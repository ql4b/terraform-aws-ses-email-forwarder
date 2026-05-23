import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3";
import { SESClient, SendRawEmailCommand } from "@aws-sdk/client-ses";

const s3 = new S3Client();
const ses = new SESClient();

const { S3_BUCKET, FORWARD_TO, FROM_EMAIL } = process.env;
const destinations = FORWARD_TO.split(",").map((e) => e.trim());

function processMessage(raw, originalRecipient) {
  const match = raw.match(/^((?:.+\r?\n)*)(\r?\n(?:.*\s+)*)/m);
  let header = match?.[1] ?? raw;
  const body = match?.[2] ?? "";

  // Add Reply-To from original sender if missing
  if (!/^reply-to:[\t ]?/im.test(header)) {
    const fromMatch = header.match(/^from:[\t ]?(.*(?:\r?\n\s+.*)*\r?\n)/im);
    if (fromMatch?.[1]) header += "Reply-To: " + fromMatch[1];
  }

  // Rewrite From to verified domain (SES requirement)
  header = header.replace(
    /^from:[\t ]?(.*(?:\r?\n\s+.*)*)/gim,
    (_, from) =>
      "From: " +
      from.replace("<", "at ").replace(">", "") +
      " <" +
      originalRecipient +
      ">"
  );

  // Replace To with forward destinations
  header = header.replace(/^to:[\t ]?(.*)/gim, "To: " + destinations.join(", "));

  // Strip headers that break forwarding
  header = header.replace(/^return-path:[\t ]?(.*)\\r?\n/gim, "");
  header = header.replace(/^sender:[\t ]?(.*)\r?\n/gim, "");
  header = header.replace(/^message-id:[\t ]?(.*)\r?\n/gim, "");
  header = header.replace(/^dkim-signature:[\t ]?.*\r?\n(\s+.*\r?\n)*/gim, "");

  return header + body;
}

export async function handler(event) {
  const record = event.Records[0];
  if (record.eventSource !== "aws:ses") throw new Error("Unexpected event source");

  const { messageId } = record.ses.mail;
  const originalRecipient = record.ses.receipt.recipients[0];

  // Fetch raw email from S3
  const { Body } = await s3.send(
    new GetObjectCommand({ Bucket: S3_BUCKET, Key: messageId })
  );
  const raw = await Body.transformToString();

  // Process and forward
  const processed = processMessage(raw, originalRecipient);

  await ses.send(
    new SendRawEmailCommand({
      RawMessage: { Data: Buffer.from(processed) },
      Source: originalRecipient,
      Destinations: destinations,
    })
  );

  return { statusCode: 200 };
}
