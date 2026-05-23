package main

import (
	"context"
	"fmt"
	"io"
	"os"
	"regexp"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/ses"
	"github.com/aws/aws-sdk-go-v2/service/ses/types"
)

var (
	s3Client  *s3.Client
	sesClient *ses.Client

	bucket       = os.Getenv("S3_BUCKET")
	forwardTo    = strings.Split(os.Getenv("FORWARD_TO"), ",")
	replyTo      = regexp.MustCompile(`(?im)^reply-to:[\t ]?`)
	fromHeader   = regexp.MustCompile(`(?im)^from:[\t ]?(.*(?:\r?\n\s+.*)*)`)
	toHeader     = regexp.MustCompile(`(?im)^to:[\t ]?(.*)`)
	returnPath   = regexp.MustCompile(`(?im)^return-path:[\t ]?(.*)\r?\n`)
	sender       = regexp.MustCompile(`(?im)^sender:[\t ]?(.*)\r?\n`)
	messageID    = regexp.MustCompile(`(?im)^message-id:[\t ]?(.*)\r?\n`)
	dkimSig      = regexp.MustCompile(`(?im)^dkim-signature:[\t ]?.*\r?\n(\s+.*\r?\n)*`)
)

func init() {
	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		panic(err)
	}
	s3Client = s3.NewFromConfig(cfg)
	sesClient = ses.NewFromConfig(cfg)
}

func processMessage(raw string, originalRecipient string) string {
	// Split header and body at first empty line
	parts := strings.SplitN(raw, "\r\n\r\n", 2)
	if len(parts) != 2 {
		parts = strings.SplitN(raw, "\n\n", 2)
	}
	if len(parts) != 2 {
		return raw
	}
	header, body := parts[0], parts[1]

	// Add Reply-To from original sender if missing
	if !replyTo.MatchString(header) {
		match := fromHeader.FindStringSubmatch(header)
		if len(match) > 1 {
			header += "\r\nReply-To: " + strings.TrimSpace(match[1])
		}
	}

	// Rewrite From to verified domain
	header = fromHeader.ReplaceAllStringFunc(header, func(m string) string {
		match := fromHeader.FindStringSubmatch(m)
		if len(match) < 2 {
			return m
		}
		from := strings.TrimSpace(match[1])
		from = strings.Replace(from, "<", "at ", 1)
		from = strings.Replace(from, ">", "", 1)
		return "From: " + from + " <" + originalRecipient + ">"
	})

	// Replace To with forward destinations
	header = toHeader.ReplaceAllString(header, "To: "+strings.Join(forwardTo, ", "))

	// Strip headers that break forwarding
	header = returnPath.ReplaceAllString(header, "")
	header = sender.ReplaceAllString(header, "")
	header = messageID.ReplaceAllString(header, "")
	header = dkimSig.ReplaceAllString(header, "")

	return header + "\r\n\r\n" + body
}

func handler(ctx context.Context, event events.SimpleEmailEvent) error {
	if len(event.Records) == 0 {
		return fmt.Errorf("no records in event")
	}

	record := event.Records[0]
	msgID := record.SES.Mail.MessageID
	originalRecipient := record.SES.Receipt.Recipients[0]

	// Fetch raw email from S3
	out, err := s3Client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: &bucket,
		Key:    &msgID,
	})
	if err != nil {
		return fmt.Errorf("s3 GetObject: %w", err)
	}
	defer out.Body.Close()

	raw, err := io.ReadAll(out.Body)
	if err != nil {
		return fmt.Errorf("read body: %w", err)
	}

	processed := processMessage(string(raw), originalRecipient)

	// Forward via SES
	_, err = sesClient.SendRawEmail(ctx, &ses.SendRawEmailInput{
		RawMessage:   &types.RawMessage{Data: []byte(processed)},
		Source:       &originalRecipient,
		Destinations: forwardTo,
	})
	if err != nil {
		return fmt.Errorf("ses SendRawEmail: %w", err)
	}

	return nil
}

func main() {
	lambda.Start(handler)
}
