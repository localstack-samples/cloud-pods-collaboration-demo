package lambda;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.util.Objects;

import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.client.config.ClientOverrideConfiguration;
import software.amazon.awssdk.core.retry.RetryPolicy;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.sns.SnsClient;

public class ProductApi {

  private static final String AWS_ENDPOINT_URL = System.getenv("AWS_ENDPOINT_URL");
  protected static final String AWS_REGION = System.getenv("AWS_REGION");
  protected ObjectMapper objectMapper = new ObjectMapper();

  // Define a custom retry policy
  // Set maximum number of retries
  RetryPolicy customRetryPolicy = RetryPolicy.builder()
          .numRetries(3)
          .build();

  // Apply the custom retry policy to ClientOverrideConfiguration
  ClientOverrideConfiguration clientOverrideConfig = ClientOverrideConfiguration.builder()
          .retryPolicy(customRetryPolicy)
          .build();


  protected DynamoDbClient ddb = Objects.isNull(AWS_ENDPOINT_URL) ?
          DynamoDbClient.builder()
                  .endpointDiscoveryEnabled(true)
                  .overrideConfiguration(clientOverrideConfig)
                  .build() :
  DynamoDbClient.builder()
      .endpointOverride(URI.create(AWS_ENDPOINT_URL))
      .credentialsProvider(
          StaticCredentialsProvider.create(AwsBasicCredentials.create("test", "test")))
      .region(Region.of("us-east-1"))
      .endpointDiscoveryEnabled(true)
      .overrideConfiguration(clientOverrideConfig)
      .build();
}
