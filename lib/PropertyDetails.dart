import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class PropertyDetailScreen extends StatelessWidget {
  final DocumentSnapshot property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final data = property.data() as Map<String, dynamic>;
    final NumberFormat currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: Text(data['title'] ?? 'Property Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Add to favorites functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share property functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Images Carousel
            SizedBox(
              height: 300,
              child: CachedNetworkImage(
                imageUrl: data['imageUrl'] ?? '',
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.home, size: 50, color: Colors.grey),
                ),
              ),
            ),

            // Property Details Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        currencyFormat.format(data['price'] ?? 0),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Address
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['location'] ?? 'No location',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Key Features
                  const Text(
                    'Key Features',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailFeature(Icons.bed, '${data['bedrooms'] ?? 0} Beds'),
                      _buildDetailFeature(Icons.bathtub, '${data['bathrooms'] ?? 0} Baths'),
                      _buildDetailFeature(Icons.square_foot, '${data['area'] ?? 0} sqft'),
                      _buildDetailFeature(Icons.star, '${data['rating']?.toStringAsFixed(1) ?? '0.0'}'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['description'] ?? 'No description available',
                    style: TextStyle(color: Colors.grey[800], fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  // Additional Details
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Property Type', data['type'] ?? 'N/A'),
                  _buildDetailRow('Year Built', data['yearBuilt']?.toString() ?? 'N/A'),
                  _buildDetailRow('Garage', '${data['garage'] ?? 0} spaces'),
                  _buildDetailRow('Floor Plan', data['floorPlan'] ?? 'N/A'),
                ],
              ),
            ),

            // Contact Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Contact agent functionality
                  },
                  child: const Text(
                    'CONTACT AGENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailFeature(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.black),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
