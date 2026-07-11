enum Permission {
  // Doctor-only
  canManageClinic,
  canManageStaff,
  canAssignRoles,
  canViewFinances,
  canUnlockVisit,
  canDeletePatient,

  // Doctor + Assistant
  canCreatePatient,
  canEditPatient,
  canCreateVisit,
  canEditVisit,
  canCompleteVisit,
  canCreateInvoice,
  canEditInvoice,
  canRecordPayment,
  canManageAppointments,
  canCheckInPatient,

  // Doctor + Assistant + Nurse
  canViewPatients,
  canViewVisits,
  canViewAppointments,
  canAddClinicalNotes,
}
