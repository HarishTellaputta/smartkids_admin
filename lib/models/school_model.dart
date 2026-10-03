class School {
  final int? id;
  final String name;
  final String code;
  final String? address;
  final String? affiliationNumber;
  final String? city;
  final String? country;
  final String? email;
  final int? establishmentYear;
  final String? facilities;
  final String? facultyInfo;
  final String? logoUrl;
  final String? phone;
  final String? postalCode;
  final String? principalMessage;
  final String? principalName;
  final String? schoolType;
  final String? state;
  final String? status;
  final String? website;

  const School({
    this.id,
    required this.name,
    required this.code,
    this.address,
    this.affiliationNumber,
    this.city,
    this.country,
    this.email,
    this.establishmentYear,
    this.facilities,
    this.facultyInfo,
    this.logoUrl,
    this.phone,
    this.postalCode,
    this.principalMessage,
    this.principalName,
    this.schoolType,
    this.state,
    this.status,
    this.website,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      address: json['address']?.toString(),
      affiliationNumber: json['affiliationNumber']?.toString(),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      email: json['email']?.toString(),
      establishmentYear: _toInt(json['establishmentYear']),
      facilities: json['facilities']?.toString(),
      facultyInfo: json['facultyInfo']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      phone: json['phone']?.toString(),
      postalCode: json['postalCode']?.toString(),
      principalMessage: json['principalMessage']?.toString(),
      principalName: json['principalName']?.toString(),
      schoolType: json['schoolType']?.toString(),
      state: json['state']?.toString(),
      status: json['status']?.toString(),
      website: json['website']?.toString(),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'code': code,
      'address': address,
      'affiliationNumber': affiliationNumber,
      'city': city,
      'country': country,
      'email': email,
      'establishmentYear': establishmentYear,
      'facilities': facilities,
      'facultyInfo': facultyInfo,
      'logoUrl': logoUrl,
      'phone': phone,
      'postalCode': postalCode,
      'principalMessage': principalMessage,
      'principalName': principalName,
      'schoolType': schoolType,
      'state': state,
      'status': status,
      'website': website,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  School copyWith({
    int? id,
    String? name,
    String? code,
    String? address,
    String? affiliationNumber,
    String? city,
    String? country,
    String? email,
    int? establishmentYear,
    String? facilities,
    String? facultyInfo,
    String? logoUrl,
    String? phone,
    String? postalCode,
    String? principalMessage,
    String? principalName,
    String? schoolType,
    String? state,
    String? status,
    String? website,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      affiliationNumber: affiliationNumber ?? this.affiliationNumber,
      city: city ?? this.city,
      country: country ?? this.country,
      email: email ?? this.email,
      establishmentYear: establishmentYear ?? this.establishmentYear,
      facilities: facilities ?? this.facilities,
      facultyInfo: facultyInfo ?? this.facultyInfo,
      logoUrl: logoUrl ?? this.logoUrl,
      phone: phone ?? this.phone,
      postalCode: postalCode ?? this.postalCode,
      principalMessage: principalMessage ?? this.principalMessage,
      principalName: principalName ?? this.principalName,
      schoolType: schoolType ?? this.schoolType,
      state: state ?? this.state,
      status: status ?? this.status,
      website: website ?? this.website,
    );
  }

  // ============================================================
  // INTEGER PARSER
  // ============================================================

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }
}
