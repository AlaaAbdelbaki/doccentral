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
  canReopenDayCloseout,

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
  canManageAttachments,

  // Doctor + Assistant + Nurse
  canViewPatients,
  canViewVisits,
  canViewAppointments,
  canAddClinicalNotes,
  canViewInventory,
  canViewAttachments,
}
