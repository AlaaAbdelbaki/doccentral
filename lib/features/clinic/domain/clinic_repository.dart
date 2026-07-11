abstract class ClinicRepository {
  Future<bool> hasLocalClinic();

  Future<void> provisionClinic({
    required String clinicName,
    required String dentistFirstName,
    required String dentistLastName,
    required String email,
    required String password,
  });
}
