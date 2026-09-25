/// Amazon Location Service Configuration
/// Configured for AWS Region eu-north-1 (Stockholm) with map resource 'Cabapp'.
class AwsLocationConfig {
  static const String region = 'eu-north-1';
  static const String mapName = 'Cabapp';
  static const String mapArn = 'arn:aws:geo:eu-north-1:004161356310:map/Cabapp';
  static const String apiKey =
      'v1.public.eyJqdGkiOiJkNGNlMjVhZC1jYjA4LTQ5NTEtOWIyYS05NjNjZGM4NGI0NTQifYsA3jiQ3CbpH2DCnn7gv2arj4-fVeB7160YBJR1ME7U1QWpZCJKex7xd0utUn2iRC-fheY7ubB02UbS4t6sOXxoCDp1a7G_YzDNGKM0iGNqJKl6BfFqNXfd5wdG-6-KoIQvz2C8lUUoeZDuGT-uF048aXj1r1bhzXmJymRiPGV-mT5fEH2N_LRr-gvsArzp4KlXUyLe4a1ZwnQhvZ9zchfWTJcKg7ZG2egUdc4kgFQwIqIs8jCcJNmFJYNGKt2FuNEKlLxkrn0R52udTjL7ZoegJehdoFX6f23uV5_9BPB5BUnwDlae4YLjzc7xEy2R0XPvjP9-yDRDOtRCdGESCrc.N2IyNTQ2ODQtOWE1YS00MmI2LTkyOTItMGJlNGMxODU1Mzc2';

  static const String styleDescriptorUrl =
      'https://maps.geo.$region.amazonaws.com/maps/v0/maps/$mapName/style-descriptor?key=$apiKey';

  static String getTileUrl(int z, int x, int y) =>
      'https://maps.geo.$region.amazonaws.com/maps/v0/maps/$mapName/tiles/$z/$x/$y?key=$apiKey';
}
