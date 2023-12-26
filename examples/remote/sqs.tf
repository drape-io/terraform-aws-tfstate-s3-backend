resource "aws_sqs_queue" "encrypted-sqs" {
    name                        = "yes-dlq-queue.fifo"
    fifo_queue                  = true
    content_based_deduplication = true
    sqs_managed_sse_enabled     = true

    tags = {
        Environment = "production"
    }
}