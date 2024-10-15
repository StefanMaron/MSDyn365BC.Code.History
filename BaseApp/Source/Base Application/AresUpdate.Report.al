#if not CLEAN17
report 11798 "Ares Update"
{
    Caption = 'Ares Update (Obsolete)';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(General)
                {
                    Caption = 'General';
                    field(AccountType; AccountType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Type';
                        Editable = false;
                        OptionCaption = 'Customer,Vendor,Contact';
                        ToolTip = 'Specifies type of update';
                    }
                    field(AccountNo; AccountNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No.';
                        Editable = false;
                        ToolTip = 'Specifies the number of the vendor/customer';
                    }
                    field(RegistrationNo; RegistrationNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Registration No.';
                        Editable = false;
                        ToolTip = 'Specifies the company''s registration number';
                    }
                }
                group(Options)
                {
                    Caption = 'Options';
                    field("FieldUpdateMask[FieldType::All]"; FieldUpdateMask[FieldType::All])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update All';
                        ToolTip = 'Specifies if all fields will be updated from ares';

                        trigger OnValidate()
                        begin
                            ValidateUpdateField(FieldType::All);
                        end;
                    }
                    field("FieldUpdateMask[FieldType::Name]"; FieldUpdateMask[FieldType::Name])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update Name';
                        ToolTip = 'Specifies if the name will be updated from ares';

                        trigger OnValidate()
                        begin
                            ValidateUpdateField(FieldType::Name);
                        end;
                    }
                    field("FieldUpdateMask[FieldType::Address]"; FieldUpdateMask[FieldType::Address])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update Address';
                        ToolTip = 'Specifies if the address will be updated from ares';

                        trigger OnValidate()
                        begin
                            ValidateUpdateField(FieldType::Address);
                        end;
                    }
                    field("FieldUpdateMask[FieldType::City]"; FieldUpdateMask[FieldType::City])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update City';
                        ToolTip = 'Specifies if the city will be updated from ares';

                        trigger OnValidate()
                        begin
                            ValidateUpdateField(FieldType::City);
                        end;
                    }
                    field("FieldUpdateMask[FieldType::PostCode]"; FieldUpdateMask[FieldType::PostCode])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update Post Code';
                        ToolTip = 'Specifies if the post code will be updated from ares';

                        trigger OnValidate()
                        begin
                            ValidateUpdateField(FieldType::PostCode);
                        end;
                    }
                    field("FieldUpdateMask[FieldType::VATRegNo]"; FieldUpdateMask[FieldType::VATRegNo])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update VAT Registration No.';
                        ToolTip = 'Specifies if the vat registration No. will be updated from ares';

                        trigger OnValidate()
                        begin
                            ValidateUpdateField(FieldType::VATRegNo);
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        PopulateFieldsFromRegLog(RecordRefGlobal, RecordVariantGlobal, RegistrationLogGlobal);
    end;

    var
        RegistrationLogGlobal: Record "Registration Log";
        DataTypeManagement: Codeunit "Data Type Management";
        RecordVariantGlobal: Variant;
        RecordRefGlobal: RecordRef;
        FieldUpdateMask: array[10] of Boolean;
        FieldType: Option ,Name,Address,City,PostCode,VATRegNo,All;
        AccountType: Option Customer,Vendor,Contact;
        AccountNo: Code[20];
        RegistrationNo: Text[20];

    [Scope('OnPrem')]
    procedure InitializeReport(RecordVariant: Variant; RegistrationLog: Record "Registration Log")
    begin
        RecordVariantGlobal := RecordVariant;
        RegistrationLogGlobal := RegistrationLog;

        DataTypeManagement.GetRecordRef(RecordVariantGlobal, RecordRefGlobal);

        AccountType := RegistrationLogGlobal."Account Type";
        AccountNo := RegistrationLogGlobal."Account No.";
        RegistrationNo := RegistrationLogGlobal."Registration No.";
    end;

    [Scope('OnPrem')]
    procedure GetRecord(var RecordRef: RecordRef)
    begin
        RecordRef := RecordRefGlobal;
    end;

    local procedure PopulateFieldsFromRegLog(var RecordRef: RecordRef; RecordVariant: Variant; RegistrationLog: Record "Registration Log")
    var
        Customer: Record Customer;
        DataTypeManagement: Codeunit "Data Type Management";
        FieldRef: FieldRef;
        FieldRef2: FieldRef;
    begin
        DataTypeManagement.GetRecordRef(RecordVariant, RecordRef);

        if FieldUpdateMask[FieldType::Name] then
            if DataTypeManagement.FindFieldByName(RecordRef, FieldRef, Customer.FieldName(Name)) then
                FieldRef.Validate(CopyStr(RegistrationLog."Verified Name", 1, FieldRef.Length));

        if FieldUpdateMask[FieldType::Address] then
            if DataTypeManagement.FindFieldByName(RecordRef, FieldRef, Customer.FieldName(Address)) then begin
                FieldRef.Value(CopyStr(RegistrationLog."Verified Address", 1, FieldRef.Length));
                if StrLen(RegistrationLog."Verified Address") > FieldRef.Length then
                    if DataTypeManagement.FindFieldByName(RecordRef, FieldRef2, Customer.FieldName("Address 2")) then
                        FieldRef.Value(CopyStr(RegistrationLog."Verified Address", FieldRef.Length + 1, FieldRef2.Length));
            end;

        if FieldUpdateMask[FieldType::City] then
            if DataTypeManagement.FindFieldByName(RecordRef, FieldRef, Customer.FieldName(City)) then
                FieldRef.Value(CopyStr(RegistrationLog."Verified City", 1, FieldRef.Length));

        if FieldUpdateMask[FieldType::PostCode] then
            if DataTypeManagement.FindFieldByName(RecordRef, FieldRef, Customer.FieldName("Post Code")) then
                FieldRef.Value(CopyStr(RegistrationLog."Verified Post Code", 1, FieldRef.Length));

        if FieldUpdateMask[FieldType::VATRegNo] then
            if DataTypeManagement.FindFieldByName(RecordRef, FieldRef, Customer.FieldName("VAT Registration No.")) then
                FieldRef.Value(CopyStr(RegistrationLog."Verified VAT Registration No.", 1, FieldRef.Length));
    end;

    local procedure ValidateUpdateField(CalledFieldType: Option)
    begin
        if CalledFieldType = FieldType::All then begin
            FieldUpdateMask[FieldType::Name] := FieldUpdateMask[FieldType::All];
            FieldUpdateMask[FieldType::Address] := FieldUpdateMask[FieldType::All];
            FieldUpdateMask[FieldType::City] := FieldUpdateMask[FieldType::All];
            FieldUpdateMask[FieldType::PostCode] := FieldUpdateMask[FieldType::All];
            FieldUpdateMask[FieldType::VATRegNo] := FieldUpdateMask[FieldType::All];
            exit;
        end;

        if not FieldUpdateMask[CalledFieldType] then
            FieldUpdateMask[FieldType::All] := false;
    end;
}
#endif