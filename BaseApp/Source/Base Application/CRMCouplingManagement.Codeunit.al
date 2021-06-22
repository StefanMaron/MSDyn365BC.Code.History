codeunit 5331 "CRM Coupling Management"
{

    trigger OnRun()
    begin
    end;

    var
        RemoveCoupledContactsUnderCustomerQst: Label 'The Customer and %2 Account have %1 child Contact records coupled to one another. Do you want to delete their couplings as well?', Comment = '%1 is a number, %2 is CRM Product Name';
        CRMProductName: Codeunit "CRM Product Name";

    procedure IsRecordCoupledToCRM(RecordID: RecordID): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        exit(CRMIntegrationRecord.IsRecordCoupled(RecordID));
    end;

    procedure IsRecordCoupledToNAV(CRMID: Guid; NAVTableID: Integer): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        NAVRecordID: RecordID;
    begin
        exit(CRMIntegrationRecord.FindRecordIDFromID(CRMID, NAVTableID, NAVRecordID));
    end;

    local procedure AssertTableIsMapped(TableID: Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.SetRange("Table ID", TableID);
        IntegrationTableMapping.FindFirst;
    end;

    procedure DefineCoupling(RecordID: RecordID; var CRMID: Guid; var CreateNew: Boolean; var Synchronize: Boolean; var Direction: Option): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CouplingRecordBuffer: Record "Coupling Record Buffer";
        CRMCouplingRecord: Page "CRM Coupling Record";
    begin
        AssertTableIsMapped(RecordID.TableNo);
        CRMCouplingRecord.SetSourceRecordID(RecordID);
        if CRMCouplingRecord.RunModal = ACTION::OK then begin
            CRMCouplingRecord.GetRecord(CouplingRecordBuffer);
            if CouplingRecordBuffer."Create New" then
                CreateNew := true
            else
                if not IsNullGuid(CouplingRecordBuffer."CRM ID") then begin
                    CRMID := CouplingRecordBuffer."CRM ID";
                    CRMIntegrationRecord.CoupleRecordIdToCRMID(RecordID, CouplingRecordBuffer."CRM ID");
                    if CouplingRecordBuffer.GetPerformInitialSynchronization then begin
                        Synchronize := true;
                        Direction := CouplingRecordBuffer.GetInitialSynchronizationDirection;
                    end;
                end else
                    exit(false);
            exit(true);
        end;
        exit(false);
    end;

    procedure RemoveCoupling(RecordID: RecordID)
    var
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
    begin
        RemoveCouplingWithTracking(RecordID, TempCRMIntegrationRecord);
    end;

    procedure RemoveCouplingWithTracking(RecordID: RecordID; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary)
    begin
        case RecordID.TableNo of
            DATABASE::Customer:
                RemoveCoupledContactsForCustomer(RecordID, TempCRMIntegrationRecord);
        end;
        RemoveSingleCoupling(RecordID, TempCRMIntegrationRecord);
    end;

    local procedure RemoveSingleCoupling(RecordID: RecordID; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.RemoveCouplingToRecord(RecordID);

        TempCRMIntegrationRecord := CRMIntegrationRecord;
        TempCRMIntegrationRecord.Skipped := false;
        if TempCRMIntegrationRecord.Insert() then;
    end;

    local procedure RemoveCoupledContactsForCustomer(RecordID: RecordID; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary)
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        CRMIntegrationRecord: Record "CRM Integration Record";
        TempContact: Record Contact temporary;
        CRMID: Guid;
    begin
        // Convert the RecordID into a Customer
        Customer.Get(RecordID);

        // Get the Company Contact for this Customer
        ContBusRel.SetCurrentKey("Link to Table", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        ContBusRel.SetRange("No.", Customer."No.");
        if ContBusRel.FindFirst then begin
            // Get all Person Contacts under it
            Contact.SetCurrentKey("Company Name", "Company No.", Type, Name);
            Contact.SetRange("Company No.", ContBusRel."Contact No.");
            Contact.SetRange(Type, Contact.Type::Person);
            if Contact.FindSet then begin
                // Count the number of Contacts coupled to CRM Contacts under the CRM Account the Customer is coupled to
                CRMIntegrationRecord.FindIDFromRecordID(RecordID, CRMID);
                if CRMAccount.Get(CRMID) then begin
                    repeat
                        if CRMIntegrationRecord.FindIDFromRecordID(Contact.RecordId, CRMID) then begin
                            CRMContact.Get(CRMID);
                            if CRMContact.ParentCustomerId = CRMAccount.AccountId then begin
                                TempContact.Copy(Contact);
                                TempContact.Insert();
                            end;
                        end;
                    until Contact.Next = 0;

                    // If any, query for breaking their couplings
                    if TempContact.Count > 0 then
                        if Confirm(StrSubstNo(RemoveCoupledContactsUnderCustomerQst, TempContact.Count, CRMProductName.FULL)) then begin
                            TempContact.FindSet;
                            repeat
                                RemoveSingleCoupling(TempContact.RecordId, TempCRMIntegrationRecord);
                            until TempContact.Next = 0;
                        end;
                end;
            end;
        end;
    end;
}

