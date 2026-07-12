enum Permission {
  // Doctor-only
  canManageClinic,
  canManageStaff,
  canAssignRoles,
  canViewFinances,
  canUnlockVisit,
  canDeletePatient,
  canVoidInvoice,
  canManageTreatmentPlan,

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
  canViewDayCloseout,
  canManageInventory,
  canConfirmDayCloseout,

  // Doctor + Assistant + Nurse
  canViewPatients,
  canViewVisits,
  canViewAppointments,
  canAddClinicalNotes,
  canViewInventory,
}
