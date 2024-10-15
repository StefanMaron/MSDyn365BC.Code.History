codeunit 18001 "GST Base Validation"
{
    //GST Ledger Entry
    [EventSubscriber(ObjectType::Table, database::"GST Ledger Entry", 'OnafterInsertEvent', '', false, false)]
    local Procedure UpdateGSTLedgerEntryOnafterInsertEvent(var rec: record "GST Ledger Entry"; RunTrigger: Boolean)
    var
        SignFactor: Integer;
        Doctype: Text;
        DocTypeEnum: Enum "Document Type Enum";
        TransType: Text;
        TransTypeEnum: Enum "Transaction Type Enum";
    begin
        if (Not RunTrigger) Or (rec."Entry Type" <> rec."Entry Type"::"Initial Entry") then
            Exit;

        if rec."Currency Code" <> '' then begin
            rec."GST Base Amount" := Abs(ConvertGSTAmountToLCY(rec."Currency Code", rec."GST Base Amount", rec."Currency Factor", rec."Posting Date", rec."GST Component Code"));
            rec."GST Amount" := Abs(ConvertGSTAmountToLCY(rec."Currency Code", rec."GST Amount", rec."Currency Factor", rec."Posting Date", rec."GST Component Code"));
        end;

        TransType := Format(rec."Transaction Type");
        Evaluate(TransTypeEnum, TransType);
        if rec."GST on Advance Payment" then
            SignFactor := GetSignAdvance(TransTypeEnum)
        else begin
            Doctype := Format(rec."Document Type");
            evaluate(DocTypeEnum, Doctype);
            SignFactor := Getsign(DocTypeEnum, TransTypeEnum);
        end;
        rec."GST Base Amount" := Abs(rec."GST Base Amount") * SignFactor;
        rec."GST Amount" := Abs(rec."GST Amount") * SignFactor;
        rec.Modify();
        UpdateDetailedGSTEntryTransNo(rec);
    end;

    //Detailed GST Ledger Entry
    [EventSubscriber(ObjectType::Table, database::"Detailed GST Ledger Entry", 'OnafterInsertEvent', '', false, false)]
    local Procedure UpdateDetailedGstLedgerEntryOnafterInsertEvent(var rec: record "Detailed GST Ledger Entry"; RunTrigger: Boolean)
    var
        GSTRegistrationNo: record "GST Registration Nos.";
        SalesRecSetup: Record "Sales & Receivables Setup";
        SignFactor: Integer;
        Doctype: Text;
        DocTypeEnum: Enum "Document Type Enum";
        OriginalDocTypeEnum: Enum "Original Doc Type";
        TransType: Text;
        TransTypeEnum: Enum "Transaction Type Enum";
        GSTPlaceofSupply: Enum "GST Place Of Supply";
        DependencyType: Text;
    begin
        if (Not RunTrigger) Or (rec."Entry Type" <> rec."Entry Type"::"Initial Entry") Or (rec."Skip Tax Engine Trigger") then
            Exit;
        SalesRecSetup.Get();
        if rec."Currency Code" <> '' then begin
            rec."GST Amount FCY" := rec."GST Amount";
            rec."GST Base Amount FCY" := rec."GST Base Amount";

            rec."GST Base Amount" := Abs(ConvertGSTAmountToLCY(rec."Currency Code", rec."GST Base Amount", rec."Currency Factor", rec."Posting Date", rec."GST Component Code"));
            rec."GST Amount" := Abs(ConvertGSTAmountToLCY(rec."Currency Code", rec."GST Amount", rec."Currency Factor", rec."Posting Date", rec."GST Component Code"));

            if rec."Transaction Type" = rec."Transaction Type"::Purchase then begin
                if rec."GST Assessable Value" <> 0 then
                    rec."GST Assessable Value" := ABS(ConvertGSTAmountToLCY
                                                (rec."Currency Code", rec."GST Assessable Value",
                                                rec."Currency Factor", rec."Posting Date", rec."GST Component Code"));
                if rec."Custom Duty Amount" <> 0 then
                    rec."Custom Duty Amount" := ABS(ConvertGSTAmountToLCY
                                                (rec."Currency Code", rec."Custom Duty Amount",
                                                rec."Currency Factor", rec."Posting Date", rec."GST Component Code"));
            end;
        end;
        GetRoundingPrecision(rec);
        if GSTRegistrationNo.Get(rec."Location  Reg. No.") then
            rec."Input Service Distribution" := GSTRegistrationNo."Input Service Distributor";

        TransType := Format(rec."Transaction Type");
        Evaluate(TransTypeEnum, TransType);
        if rec."GST on Advance Payment" then
            SignFactor := GetSignAdvance(TransTypeEnum)
        else
            SignFactor := Getsign(DocTypeEnum, TransTypeEnum);
        Doctype := Format(rec."Document Type");
        evaluate(DocTypeEnum, Doctype);
        rec."GST Base Amount" := Abs(rec."GST Base Amount") * SignFactor;
        rec."GST Amount" := Abs(rec."GST Amount") * SignFactor;
        if rec."Document Type" = rec."Document Type"::"Credit Memo" then
            rec.Quantity := abs(rec.Quantity)
        else
            rec.Quantity := abs(rec.Quantity) * SignFactor;
        rec."Remaining Base Amount" := rec."GST Base Amount";
        rec."Remaining GST Amount" := rec."GST Amount";
        Evaluate(OriginalDocTypeEnum, Doctype);
        rec."Original Doc. Type" := OriginalDocTypeEnum;
        rec."Original Doc. No." := rec."Document No.";
        rec."Remaining Quantity" := rec.Quantity;
        rec."Amount Loaded on Item" := ABS(rec."Amount Loaded on Item");
        if (rec."Amount Loaded on Item" <> rec."GST Amount") and (rec."Amount Loaded on Item" <> 0)
            and (rec."GST Credit" = rec."GST Credit"::"Non-Availment") then
            rec."Amount Loaded on Item" := rec."GST Amount";

        if rec."GST Amount FCY" <> 0 then
            rec."GST Amount FCY" := Abs(rec."GST Amount FCY") * SignFactor;

        if rec."GST Base Amount FCY" <> 0 then
            rec."GST Base Amount FCY" := Abs(rec."GST Base Amount FCY") * SignFactor;

        if rec."GST Amount" > 0 then
            rec.Positive := true
        else
            rec.Positive := false;

        if rec."Transaction Type" = rec."Transaction Type"::Sales then begin
            DependencyType := format(SalesRecSetup."GST Dependency Type");
            Evaluate(GSTPlaceofSupply, DependencyType);
            rec."GST Place of Supply" := GSTPlaceofSupply;
        end;

        if rec."Transaction Type" = rec."Transaction Type"::Purchase then begin
            rec."Source Type" := rec."Source Type"::Vendor;
            rec."Nature of Supply" := rec."Nature of Supply"::B2B;
        end else
            if rec."Transaction Type" = rec."Transaction Type"::Sales then begin
                rec."Source Type" := rec."Source Type"::Customer;
                if rec."GST Customer Type" = rec."GST Customer Type"::Unregistered then
                    rec."Nature of Supply" := rec."Nature of Supply"::B2C
                else
                    rec."Nature of Supply" := rec."Nature of Supply"::B2B;
            end;
        rec.Modify();
    end;

    //Company Information Validation - Subscribers 
    [EventSubscriber(ObjectType::Table, database::"Company Information", 'OnAfterValidateEvent', 'P.A.N. No.', false, false)]
    local procedure ValidatePANNoOnAfterValidateEvent(var rec: record "Company Information")
    begin
        if rec."P.A.N. No." <> '' then
            CheckGSTRegBlankInRef(rec."P.A.N. No.");
    end;

    [EventSubscriber(ObjectType::Table, database::"Company Information", 'OnAfterValidateEvent', 'State Code', False, False)]
    local procedure ValidateCompanyStateCodeOnAfterValidateEvent(var rec: record "Company Information")
    begin
        rec.TestField("GST Registration No.", '');
    end;

    [EventSubscriber(ObjectType::Table, database::"Company Information", 'OnAfterValidateEvent', 'GST Registration No.', False, False)]
    local procedure ValdiateGSTRegistrationNoOnAfterValidateEvent(var rec: record "Company Information")
    begin
        rec.TestField("State Code");
    end;

    //GST Group Validations - Subscribers
    [EventSubscriber(ObjectType::table, database::"Gst Group", 'OnafterValidateevent', 'GST Group Type', False, False)]
    local procedure ValidateGSTGroupTypeOnafterValidateevent(var rec: record "GST Group")
    begin
        rec.TestField("Reverse Charge", false);
    end;

    [EventSubscriber(ObjectType::table, database::"Gst Group", 'OnafterValidateevent', 'Reverse Charge', False, False)]
    local procedure ValidateReverseChargeOnafterValidateevent(var rec: record "GST Group")
    begin
        rec.TestField("GST Group Type", rec."GST Group Type"::Service);
    end;

    //GST Registration Nos. - Subscribers
    [EventSubscriber(ObjectType::table, database::"GST Registration Nos.", 'onaftervalidateevent', 'Code', false, false)]
    local Procedure ValidateRegistrationCodeonaftervalidateevent(
        var rec: record "GST Registration Nos.";
        var xrec: record "GST Registration Nos.")
    begin
        if xrec.Code <> '' then
            CheckDependentDataInCompanyAndLocationAtEditing(xrec);
    end;

    [EventSubscriber(ObjectType::table, database::"GST Registration Nos.", 'onaftervalidateevent', 'State Code', false, false)]
    local procedure ValidateStateCodeonaftervalidateevent(var rec: record "GST Registration Nos.")
    var
        CompanyInformation: record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."P.A.N. No." <> '' then
            CheckGSTRegistrationNo(rec."State Code", rec.Code, CompanyInformation."P.A.N. No.")
        else
            Error(PANErr);
    end;

    [EventSubscriber(ObjectType::table, database::"GST Registration Nos.", 'OnAfterDeleteEvent', '', false, false)]
    local procedure ValidateDeleteOnAfterDeleteEvent(var rec: record "GST Registration Nos.")
    begin
        CheckDependentDataInCompanyAndLocation(rec);
    end;

    //GST Posting Setup - Subscribers
    [EventSubscriber(ObjectType::table, database::"GST Posting Setup", 'OnafterValidateevent', 'receivable Account', False, False)]
    local procedure ValidatereceivableAccountOnafterValidateevent(var rec: record "GST Posting Setup")
    begin
        CheckGLAcc(rec."receivable Account");
    end;

    [EventSubscriber(ObjectType::table, database::"GST Posting Setup", 'OnafterValidateevent', 'Payable Account', False, False)]
    local procedure ValidatePayableAccountOnafterValidateevent(var rec: record "GST Posting Setup")
    begin
        CheckGLAcc(rec."Payable Account");
    end;

    [EventSubscriber(ObjectType::table, database::"GST Posting Setup", 'OnafterValidateevent', 'receivable Account (Interim)', False, False)]
    local procedure ValidatereceivableAccountInterimOnafterValidateevent(var rec: record "GST Posting Setup")
    begin
        CheckGLAcc(rec."receivable Account (Interim)");
    end;

    [EventSubscriber(ObjectType::table, database::"GST Posting Setup", 'OnafterValidateevent', 'Payables Account (Interim)', False, False)]
    local procedure ValidatePayablesAccountInterimOnafterValidateevent(var rec: record "GST Posting Setup")
    begin
        CheckGLAcc(rec."Payables Account (Interim)");
    end;

    [EventSubscriber(ObjectType::table, database::"GST Posting Setup", 'OnafterValidateevent', 'Expense Account', False, False)]
    local procedure ValidateExpenseAccountOnafterValidateevent(var rec: record "GST Posting Setup")
    begin
        CheckGLAcc(rec."Expense Account");
    end;

    [EventSubscriber(ObjectType::table, database::"GST Posting Setup", 'OnafterValidateevent', 'Refund Account', False, False)]
    local procedure ValidateRefundAccountOnafterValidateevent(var rec: record "GST Posting Setup")
    begin
        CheckGLAcc(rec."Refund Account");
    end;

    [EventSubscriber(ObjectType::table, database::"GST Posting Setup", 'OnafterValidateevent', 'receivable Acc. Interim (Dist)', False, False)]
    local procedure ValidatereceivableAccInterimDistOnafterValidateevent(var rec: record "GST Posting Setup")
    begin
        CheckGLAcc(rec."receivable Acc. Interim (Dist)");
    end;

    [EventSubscriber(ObjectType::table, database::"GST Posting Setup", 'OnafterValidateevent', 'receivable Acc. (Dist)', False, False)]
    local procedure ValidatereceivableAccDisOnafterValidateevent(var rec: record "GST Posting Setup")
    begin
        CheckGLAcc(rec."receivable Acc. (Dist)");
    end;

    [EventSubscriber(ObjectType::table, database::"GST Posting Setup", 'OnafterValidateevent', 'GST Credit Mismatch Account', False, False)]
    local procedure ValidateGSTCreditMismatchAccountOnafterValidateevent(var rec: record "GST Posting Setup")
    begin
        CheckGLAcc(rec."GST Credit Mismatch Account");
    end;

    [EventSubscriber(ObjectType::table, database::"GST Posting Setup", 'OnafterValidateevent', 'GST TDS receivable Account', False, False)]
    local procedure ValidateGSTTDSreceivableAccountOnafterValidateevent(var rec: record "GST Posting Setup")
    begin
        CheckGLAcc(rec."GST TDS receivable Account");
    end;

    [EventSubscriber(ObjectType::table, database::"GST Posting Setup", 'OnafterValidateevent', 'GST TCS receivable Account', False, False)]
    local procedure ValidateGSTTCSreceivableAccountOnafterValidateevent(var rec: record "GST Posting Setup")
    begin
        CheckGLAcc(rec."GST TCS receivable Account");
    end;

    [EventSubscriber(ObjectType::table, database::"GST Posting Setup", 'OnafterValidateevent', 'GST TCS Payable Account', False, False)]
    local procedure ValidateGSTTCSPayableAccountOnafterValidateevent(var rec: record "GST Posting Setup")
    begin
        CheckGLAcc(rec."GST TCS Payable Account");
    end;

    //Location Subscribers
    [EventSubscriber(ObjectType::table, database::Location, 'OnafterValidateevent', 'State Code', false, false)]
    local procedure CheckBlankGSTRegNoOnafterValidateevent(var rec: record Location)
    begin
        rec.TestField("GST Registration No.", '');
    end;

    [EventSubscriber(ObjectType::table, database::Location, 'OnafterValidateevent', 'GST Registration No.', false, false)]
    local procedure validateGSTRegistrationNoOnafterValidateevent(var rec: record Location)
    var
        GSTRegistrationNos: record "GST Registration Nos.";
    begin
        rec."GST Input Service Distributor" := FALSE;
        if GSTRegistrationNos.Get(rec."GST Registration No.") then
            rec."GST Input Service Distributor" := GSTRegistrationNos."Input Service Distributor";
    end;

    //State Subscribers
    [EventSubscriber(ObjectType::Table, database::State, 'OnAfterValidateEvent', 'State Code (GST Reg. No.)', False, False)]
    local procedure ValidateStateCodeGSTRegNoOnAfterValidateEvent(var rec: record State)
    begin
        if (rec."State Code (GST Reg. No.)") <> '' then
            if strlen(rec."State Code (GST Reg. No.)") <> 2 then
                Error(LengthStateErr);
        rec.TestField(Code);
        CheckUniqueGSTRegNoStateCode(rec."State Code (GST Reg. No.)");
    end;

    //item Subscribers
    [EventSubscriber(ObjectType::Table, database::item, 'OnAfterValidateEvent', 'GST Group Code', False, False)]
    local procedure ValidateitemGSTGroupCodeOnAfterValidateEvent(var rec: record Item; var xrec: record Item)
    begin
        if rec."GST Group Code" <> xrec."GST Group Code" then
            rec."HSN/SAC Code" := '';
    end;

    //G/L Account Subscribers
    [EventSubscriber(ObjectType::Table, database::"G/L Account", 'OnAfterValidateEvent', 'GST Group Code', False, False)]
    local procedure validateGLGSTGroupCodeOnAfterValidateEvent(var rec: record "G/L Account"; var xrec: record "G/L Account")
    begin
        if rec."GST Group Code" <> xrec."GST Group Code" then
            rec."HSN/SAC Code" := '';
    end;

    //FA Subscribers
    [EventSubscriber(ObjectType::Table, database::"Fixed Asset", 'OnAfterValidateEvent', 'GST Group Code', False, False)]
    local procedure ValidateFAGSTGroupCodeOnAfterValidateEvent(var rec: record "Fixed Asset"; var xrec: record "Fixed Asset")
    begin
        if rec."GST Group Code" <> xrec."GST Group Code" then
            rec."HSN/SAC Code" := '';
    end;

    //Resource Validations
    [EventSubscriber(ObjectType::Table, database::Resource, 'OnAfterValidateEvent', 'GST Group Code', False, False)]
    local procedure ValidateResourceGSTGroupCodeOnAfterValidateEvent(var rec: record Resource; var xrec: record Resource)
    begin
        if rec."GST Group Code" <> xrec."GST Group Code" then
            rec."HSN/SAC Code" := '';
    end;

    //ItemCharge Validations
    [EventSubscriber(ObjectType::Table, database::"Item Charge", 'OnAfterValidateEvent', 'GST Group Code', False, False)]
    local procedure ValidateItemChargeGSTGroupCodeOnAfterValidateEvent(
        var rec: record "Item Charge";
        var xrec: record "Item Charge")
    begin
        if rec."GST Group Code" <> xrec."GST Group Code" then
            rec."HSN/SAC Code" := '';
    end;

    //ServiceCost Validations
    [EventSubscriber(ObjectType::Table, database::"Service Cost", 'OnAfterValidateEvent', 'GST Group Code', False, False)]
    local procedure ValidateServiceCostGSTGroupCodeOnAfterValidateEvent(
        var rec: record "Service Cost";
        var xrec: record "Service Cost")
    begin
        if rec."GST Group Code" <> xrec."GST Group Code" then
            rec."HSN/SAC Code" := '';
    end;

    //Bank Account Validations
    [EventSubscriber(ObjectType::Table, database::"Bank Account", 'OnAfterValidateEvent', 'State Code', False, False)]
    local Procedure ValidateBankAccStateCodeOnAfterValidateEvent(var rec: record "Bank Account")
    begin
        if rec."GST Registration Status" = rec."GST Registration Status"::Registered then
            rec.TestField("GST Registration No.", '');
    end;

    [EventSubscriber(ObjectType::Table, database::"Bank Account", 'OnAfterValidateEvent', 'GST Registration Status', False, False)]
    local procedure ValidateGSTRegistrationStatusOnAfterValidateEvent(var rec: record "Bank Account")
    begin
        if rec."GST Registration Status" = rec."GST Registration Status"::Registered then begin
            rec.TestField("GST Registration No.");
            rec.TestField("State Code");
            CheckGSTRegistrationNo(rec."State Code", rec."GST Registration No.", '')
        end else
            rec.TestField("GST Registration No.", '');
    end;

    [EventSubscriber(ObjectType::Table, database::"Bank Account", 'OnAfterValidateEvent', 'GST Registration No.', False, False)]
    local procedure ValidateGSTRegistrationNoBankAccOnAfterValidateEvent(var rec: record "Bank Account")
    begin
        if rec."GST Registration No." <> '' then begin
            rec.TestField("State Code");
            CheckGSTRegistrationNo(rec."State Code", rec."GST Registration No.", '');
            rec."GST Registration Status" := rec."GST Registration Status"::Registered
        end else
            rec."GST Registration Status" := rec."GST Registration Status"::" ";
    end;

    local procedure CheckGSTRegBlankInRef(PANNO: Code[20])
    var
        GSTRegistrationNos: record "GST Registration Nos.";
    begin
        if GSTRegistrationNos.FINDSET() then
            repeat
                if PANNO <> COPYSTR(GSTRegistrationNos.Code, 3, 10) then
                    Error(CompnayGSTPANErr, GSTRegistrationNos.Code, GSTRegistrationNos."State Code");
            until GSTRegistrationNos.NEXT() = 0;
    end;
    //Same Functon in Called in GST Sales
    procedure CheckGSTRegistrationNo(StateCode: Code[10]; RegistrationNo: code[20]; PANNo: code[20])
    var
        State: record State;
        Position: Integer;
    begin
        if RegistrationNo = '' then
            Exit;

        if StrLen(RegistrationNo) <> 15 then
            Error(LengthErr);

        State.Get(StateCode);
        if State."State Code (GST Reg. No.)" <> COPYSTR(RegistrationNo, 1, 2) then
            Error(StateCodeErr, StateCode, State."State Code (GST Reg. No.)");

        if PANNo <> '' then
            if PANNo <> COPYSTR(RegistrationNo, 3, 10) then
                Error(SamePanErr, PANNo);

        for Position := 3 to 15 do
            case Position OF
                3 .. 7, 12:
                    CheckIsAlphabet(RegistrationNo, Position);
                8 .. 11:
                    CheckIsNumeric(RegistrationNo, Position);
                13:
                    CheckIsNumeric(RegistrationNo, Position);
                14:
                    CheckForZValue(RegistrationNo, Position);
                15:
                    CheckIsAlphaNumeric(RegistrationNo, Position)
            end;
    end;

    local procedure CheckIsAlphabet(RegistrationNo: Code[20]; Position: Integer)
    begin
        if not (COPYSTR(RegistrationNo, Position, 1) IN ['A' .. 'Z']) then
            Error(OnlyAlphabetErr, Position);
    end;

    local procedure CheckIsNumeric(RegistrationNo: Code[20]; Position: Integer)
    begin
        if not (COPYSTR(RegistrationNo, Position, 1) IN ['0' .. '9']) then
            Error(OnlyNumericErr, Position);
    end;

    local procedure CheckIsAlphaNumeric(RegistrationNo: Code[20]; Position: Integer)
    begin
        if not ((COPYSTR(RegistrationNo, Position, 1) IN ['0' .. '9']) or (COPYSTR(RegistrationNo, Position, 1) IN ['A' .. 'Z'])) then
            Error(OnlyAlphaNumericErr, Position);
    end;

    local procedure CheckForZValue(RegistrationNo: Code[20]; Position: Integer)
    begin
        if not (COPYSTR(RegistrationNo, Position, 1) IN ['Z']) then
            Error(OnlyZErr, Position);
    end;

    local procedure CheckDependentDataInCompanyAndLocation(var GstRegNo: record "GST Registration Nos.")
    var
        CompanyInformation: record "Company Information";
        Location: record location;
    begin
        if not CompanyInformation.Get() then
            exit;
        if CompanyInformation."GST Registration No." = GstRegNo.Code then
            Error(GSTCompyErr, GstRegNo.Code);

        Location.SetRange("GST Registration No.", GstRegNo.Code);
        if Location.FindFirst() then
            Error(GSTLocaErr, GstRegNo.Code, Location.Code);
    end;

    local procedure CheckDependentDataInCompanyAndLocationAtEditing(var GstRegNo: record "GST Registration Nos.")
    var
        CompanyInformation: record "Company Information";
        Location: record Location;
    begin
        if not CompanyInformation.Get() then
            exit;
        if CompanyInformation."GST Registration No." <> '' then
            if CompanyInformation."GST Registration No." = GstRegNo.Code then
                Error(GSTCompyErr, GstRegNo.Code);

        Location.SetRange("GST Registration No.", GstRegNo.Code);
        if Location.FindFirst() then
            if Location."GST Registration No." <> '' then
                if Location."GST Registration No." = GstRegNo.Code then
                    Error(GSTLocaErr, GstRegNo.Code, Location.Code);
    end;

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
        end;
    end;

    local procedure CheckUniqueGSTRegNoStateCode(StateCodeGSTRegNo: code[10])
    var
        State: record state;
    begin
        if StateCodeGSTRegNo <> '' then begin
            State.SetRange("State Code (GST Reg. No.)", "StateCodeGSTRegNo");
            if not State.IsEmpty() then
                Error(
                    GSTStateCodeErr,
                    State.FIELDCAPTION("State Code (GST Reg. No.)"),
                    StateCodeGSTRegNo);
        end;
    end;
    //Same Funciton is called in GST Sales
    procedure VerifyPOSOutOfIndia(PartyType: Enum "Party Type";
                                                 LocationStateCode: Code[10];
                                                 VendCustStateCode: Code[10];
                                                 GSTVendorType: Enum "GST Vendor Type";
                                                 GSTCustomerType: Enum "GST Customer Type")
    begin
        if LocationStateCode <> VendCustStateCode then
            Error(POSLOCDiffErr);

        if PartyType = PartyType::Customer then begin
            if not (GSTCustomerType IN [GSTCustomerType::" ",
                                        GSTCustomerType::Registered,
                                        GSTCustomerType::Unregistered,
                                        GSTCustomerType::"Deemed Export"])
            then
                Error(CustGSTTypeErr);
        end else
            if not (GSTVendorType IN [GSTVendorType::Registered, GSTVendorType::" "]) then
                Error(VendGSTTypeErr);
    end;

    local procedure ConvertGSTAmountToLCY(
         CurrencyCode: Code[10];
         Amount: Decimal;
         CurrencyFactor: Decimal;
         PostingDate: Date;
         ComponentCode: code[10]): Decimal
    var
        CurrExchRate: record "Currency Exchange Rate";
        TaxComponent: record "Tax Component";
        TaxTypeSetp: record "Tax Type Setup";
    begin
        if CurrencyCode <> '' then begin
            TaxTypeSetp.Get();
            TaxTypeSetp.TestField(code);

            TaxComponent.SetRange("Tax Type", TaxTypeSetp.Code);
            TaxComponent.SetRange(Name, ComponentCode);
            TaxComponent.FindFirst();
            Exit(Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
            PostingDate, CurrencyCode, Amount, CurrencyFactor), TaxComponent."Rounding Precision"));
        end;
    end;

    local procedure GetRoundingPrecision(var DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry"): Decimal
    var
        TaxComponent: record "Tax Component";
        TaxTypeSetp: record "Tax Type Setup";
        GSTInvRounfingType: Enum "GST Inv Rounding Type";
        Direction: Text;
    begin
        TaxTypeSetp.Get();
        TaxTypeSetp.TestField(code);
        TaxComponent.SetRange("Tax Type", TaxTypeSetp.Code);
        TaxComponent.SetRange(Name, DetailedGSTLedgerEntry."GST Component Code");
        TaxComponent.FindFirst();
        Direction := Format(TaxComponent.Direction);
        Evaluate(GSTInvRounfingType, Direction);
        DetailedGSTLedgerEntry."GST Rounding Precision" := TaxComponent."Rounding Precision";
        DetailedGSTLedgerEntry."GST Rounding Type" := GSTInvRounfingType;
    end;

    local Procedure GetSign(DocumentType: enum "Document Type Enum";
                                              TransactionType: enum "Transaction Type Enum") Sign: Integer
    begin
        if DocumentType IN [DocumentType::Order, DocumentType::Invoice, DocumentType::Quote, DocumentType::"Blanket Order"] then
            Sign := 1
        else
            Sign := -1;
        if TransactionType = TransactionType::Purchase then
            Sign := Sign * 1
        else
            Sign := Sign * -1;
        Exit(Sign);
    end;

    local Procedure GetSignAdvance(TransactionType: enum "Transaction Type Enum") Sign: Integer
    begin
        if TransactionType = TransactionType::Purchase then
            Sign := 1
        else
            Sign := -1;
        Exit(Sign);
    end;

    local Procedure GetVendorLedgerEntryNo(TransactionNo: Integer): Integer
    var
        VendorLedgerEntry: record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetCurrentKey("Transaction No.");
        VendorLedgerEntry.SetRange("Transaction No.", TransactionNo);
        if VendorLedgerEntry.FindFirst() then
            Exit(VendorLedgerEntry."Entry No.")
    end;

    local Procedure GetCustomerLedgerEntryNo(TransactionNo: Integer): Integer
    var
        CustLedgerEntry: record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetCurrentKey("Transaction No.");
        CustLedgerEntry.SetRange("Transaction No.", TransactionNo);
        if CustLedgerEntry.FindFirst() then
            Exit(CustLedgerEntry."Entry No.")
    end;

    local procedure UpdateDetailedGSTEntryTransNo(GSTLedgerEntry: record "GST Ledger Entry")
    Var
        DetailedGSTLedgerEntry: record "Detailed GST Ledger Entry";
        TransType: Text;
        DocumentType: Text;
        TransTypeEnum: Enum "Detail Ledger Transaction Type";
        DocumentTypeEnum: Enum "GST Document Type";
    begin
        TransType := Format(GSTLedgerEntry."Transaction Type");
        Evaluate(TransTypeEnum, TransType);
        DocumentType := Format(GSTLedgerEntry."Document Type");
        Evaluate(DocumentTypeEnum, DocumentType);
        DetailedGSTLedgerEntry.Reset();
        DetailedGSTLedgerEntry.SetCurrentKey("Transaction Type", "Entry Type", "Document Type", "Document No.", "Posting Date");
        DetailedGSTLedgerEntry.SetRange("Transaction Type", TransTypeEnum);
        DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::"Initial Entry");
        DetailedGSTLedgerEntry.SetRange("Document Type", DocumentTypeEnum);
        DetailedGSTLedgerEntry.SetRange("Document No.", GSTLedgerEntry."Document No.");
        DetailedGSTLedgerEntry.SetRange("Posting Date", GSTLedgerEntry."Posting Date");
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                DetailedGSTLedgerEntry."Transaction No." := GSTLedgerEntry."Transaction No.";
                if GSTLedgerEntry."Transaction Type" = GSTLedgerEntry."Transaction Type"::Sales then
                    DetailedGSTLedgerEntry."CLE/VLE Entry No." := GetCustomerLedgerEntryNo(GSTLedgerEntry."Transaction No.")
                else
                    if GSTLedgerEntry."Transaction Type" = GSTLedgerEntry."Transaction Type"::Purchase then
                        DetailedGSTLedgerEntry."CLE/VLE Entry No." := GetVendorLedgerEntryNo(GSTLedgerEntry."Transaction No.");
                DetailedGSTLedgerEntry.Modify();
            until DetailedGSTLedgerEntry.Next() = 0;
    end;

    procedure OpenGSTEntries(FromEntry: Integer; ToEntry: Integer)
    var
        GSTLedgerEntry: Record "GST Ledger Entry";
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Entry No.", FromEntry, ToEntry);
        if GLEntry.FindFirst() then begin
            GSTLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
            Page.Run(0, GSTLedgerEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterRunWithoutCheck', '', false, false)]
    local procedure CheckProvisionalEntry(var GenJnlLine: Record "Gen. Journal Line")
    var
        TaxTransactionValue: Record "Tax Transaction Value";
    begin
        TaxTransactionValue.SetRange("Tax Record ID", GenJnlLine.RecordId);
        if (GenJnlLine."TDS Section Code" = '') or (Not GenJnlLine."Provisional Entry") or (TaxTransactionValue.IsEmpty) then
            exit;

        GenJnlLine.TestField("GST Group Code", '');
    end;

    procedure OpenDetailedGSTEntries(FromEntry: Integer; ToEntry: Integer)
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Entry No.", FromEntry, ToEntry);
        if GLEntry.FindFirst() then begin
            DetailedGSTLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
            page.Run(0, DetailedGSTLedgerEntry);
        end;
    end;

    var
        LengthErr: label 'The Length of the GST Registration Nos. must be 15.';
        StateCodeErr: Label 'The GST Registration No. for the state %1 should start with %2.', Comment = '%1 = StateCode ; %2 = GST Reg. No';
        OnlyAlphabetErr: label 'Only Alphabet is allowed in the position %1.', Comment = '%1 = Position';
        OnlyNumericErr: label 'Only Numeric is allowed in the position %1.', Comment = '%1 = Position';
        OnlyAlphaNumericErr: label 'Only AlphaNumeric is allowed in the position %1.', Comment = '%1 = Position';
        OnlyZErr: label 'Only Z value is allowed in the position %1.', Comment = '%1 = Position';
        SamePanErr: label 'In GST Registration No from postion 3 to 12 the value should be same as the PAN No. %1.', Comment = '%1 = PANNo';
        PANErr: label 'PAN No. must be entered in Company Information.';
        GSTCompyErr: label 'Please delete the GST Registration No. %1 from Company Information.', Comment = '%1 =GstRegNo';
        GSTLocaErr: label 'Please delete the GST Registration No. %1 from Location %2.', Comment = '%1 = GstRegNo ;%2 = LocationCode';
        CompnayGSTPANErr: label 'Please delete the record %1 from GST Registration No.of state %2  since the PAN No. is not same as in Company Information.', Comment = '%1 = GstRegNo ; %2 = StateCode';
        GSTStateCodeErr: Label '%1 %2 is already in use', Comment = '%1 = StateCode ; %2 = GstRegNo';
        LengthStateErr: Label 'The Length of the State Code (GST Reg. No.) must be 2.';
        POSLOCDiffErr: Label 'You can select POS Out Of India field on header only if Customer / Vendor State Code and Location State Code are same.';
        CustGSTTypeErr: Label 'You can select POS Out Of India field on header only if GST Customer/Vednor Type is Registered, Unregistered or Deemed Export.';
        VendGSTTypeErr: Label 'You can select POS Out Of India field on header only if GST Vendor Type is Registered.';
}