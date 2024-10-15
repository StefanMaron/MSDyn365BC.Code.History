table 11000002 "Payment History Line"
{
    Caption = 'Payment History Line';
    DrillDownPageID = "Payment History Line Overview";
    LookupPageID = "Payment History Line Overview";

    fields
    {
        field(1; "Run No."; Code[20])
        {
            Caption = 'Run No.';
            Editable = false;
            TableRelation = "Payment History"."Run No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(3; "Account Type"; Option)
        {
            Caption = 'Account Type';
            Editable = false;
            OptionCaption = 'Customer,Vendor,Employee';
            OptionMembers = Customer,Vendor,Employee;
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            Editable = false;
            TableRelation = IF ("Account Type" = CONST(Customer)) Customer."No."
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor."No."
            ELSE
            IF ("Account Type" = CONST(Employee)) Employee."No.";
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
            Editable = false;
        }
        field(6; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        field(7; Bank; Code[20])
        {
            Caption = 'Bank';
            Editable = false;
            TableRelation = IF ("Account Type" = CONST(Customer)) "Customer Bank Account".Code WHERE("Customer No." = FIELD("Account No."))
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Account No."))
            ELSE
            IF ("Account Type" = CONST(Employee)) Employee."No." WHERE("Employee No. Filter" = FIELD("Account No."));
        }
        field(8; "Our Bank"; Code[20])
        {
            Caption = 'Our Bank';
            Editable = false;
            TableRelation = "Bank Account"."No.";
        }
        field(9; "Order"; Option)
        {
            Caption = 'Order';
            Editable = false;
            OptionCaption = ' ,Debit,Credit';
            OptionMembers = " ",Debit,Credit;
        }
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(11; "Description 1"; Text[32])
        {
            Caption = 'Description 1';
            Editable = false;

            trigger OnValidate()
            begin
                TestField(Status, Status::New);
            end;
        }
        field(12; "Description 2"; Text[32])
        {
            Caption = 'Description 2';
            Editable = false;

            trigger OnValidate()
            begin
                TestField(Status, Status::New);
            end;
        }
        field(13; "Description 3"; Text[32])
        {
            Caption = 'Description 3';
            Editable = false;

            trigger OnValidate()
            begin
                TestField(Status, Status::New);
            end;
        }
        field(14; "Description 4"; Text[32])
        {
            Caption = 'Description 4';
            Editable = false;

            trigger OnValidate()
            begin
                TestField(Status, Status::New);
            end;
        }
        field(15; Identification; Code[80])
        {
            Caption = 'Identification';
            Editable = false;
        }
        field(16; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
            Editable = false;
        }
        field(18; "Transaction Mode"; Code[20])
        {
            Caption = 'Transaction Mode';
            Editable = false;
            TableRelation = "Transaction Mode".Code WHERE("Account Type" = FIELD("Account Type"));
        }
        field(19; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'New,Transmitted,Request for Cancellation,Rejected,Cancelled,Posted';
            OptionMembers = New,Transmitted,"Request for Cancellation",Rejected,Cancelled,Posted;
        }
        field(20; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(23; "Payment/Receipt"; Option)
        {
            Caption = 'Payment/Receipt';
            Editable = false;
            OptionCaption = 'Payment,Receipt';
            OptionMembers = Payment,Receipt;
        }
        field(24; "Amount Paymt. in Process (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount Paymt. in Process (LCY)';
            Editable = false;
        }
        field(25; Docket; Boolean)
        {
            Caption = 'Docket';
            Editable = false;
        }
        field(100; "Account Holder Name"; Text[100])
        {
            Caption = 'Account Holder Name';
            Editable = false;
        }
        field(101; "Account Holder Address"; Text[100])
        {
            Caption = 'Account Holder Address';
            Editable = false;
        }
        field(102; "Account Holder Post Code"; Code[20])
        {
            Caption = 'Account Holder Post Code';
            Editable = false;
            TableRelation = "Post Code".Code;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                County: Text[30];
            begin
                PostCode.ValidatePostCode(
                  "Account Holder City", "Account Holder Post Code", County, "Acc. Hold. Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(103; "Account Holder City"; Text[30])
        {
            Caption = 'Account Holder City';
            Editable = false;
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(104; "Acc. Hold. Country/Region Code"; Code[10])
        {
            Caption = 'Acc. Hold. Country/Region Code';
            Editable = false;
            TableRelation = "Country/Region".Code;
        }
        field(105; "National Bank Code"; Code[10])
        {
            Caption = 'National Bank Code';
            Editable = false;
        }
        field(106; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            Editable = false;
        }
        field(110; "Nature of the Payment"; Option)
        {
            Caption = 'Nature of the Payment';
            OptionCaption = ' ,Goods,Transito Trade,Invisible- and Capital Transactions,Transfer to Own Account,Other Registrated BFI';
            OptionMembers = " ",Goods,"Transito Trade","Invisible- and Capital Transactions","Transfer to Own Account","Other Registrated BFI";
        }
        field(111; "Registration No. DNB"; Text[8])
        {
            Caption = 'Registration No. DNB';
        }
        field(112; "Description Payment"; Text[30])
        {
            Caption = 'Description Payment';
        }
        field(113; "Item No."; Text[2])
        {
            Caption = 'Item No.';
        }
        field(114; "Traders No."; Text[4])
        {
            Caption = 'Traders No.';
        }
        field(115; Urgent; Boolean)
        {
            Caption = 'Urgent';
        }
        field(120; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
            Editable = false;
        }
        field(121; "Bank Address"; Text[100])
        {
            Caption = 'Bank Address';
            Editable = false;
        }
        field(122; "Bank City"; Text[30])
        {
            Caption = 'Bank City';
            Editable = false;
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(123; "Bank Country/Region"; Code[10])
        {
            Caption = 'Bank Country/Region';
            Editable = false;
            TableRelation = "Country/Region".Code;
        }
        field(130; "Transfer Cost Domestic"; Option)
        {
            Caption = 'Transfer Cost Domestic';
            Editable = false;
            OptionCaption = 'Principal,Balancing Account Holder';
            OptionMembers = Principal,"Balancing Account Holder";
        }
        field(131; "Transfer Cost Foreign"; Option)
        {
            Caption = 'Transfer Cost Foreign';
            Editable = false;
            OptionCaption = 'Principal,Balancing Account Holder';
            OptionMembers = Principal,"Balancing Account Holder";
        }
        field(132; "Abbrev. National Bank Code"; Code[3])
        {
            Caption = 'Abbrev. National Bank Code';
        }
        field(133; IBAN; Code[50])
        {
            Caption = 'IBAN';
        }
        field(134; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            Editable = false;
            TableRelation = "SEPA Direct Debit Mandate".ID;
        }
        field(135; "Direct Debit Mandate Counter"; Integer)
        {
            Caption = 'Direct Debit Mandate Counter';
            Editable = false;

            trigger OnValidate()
            var
                SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
            begin
                if SEPADirectDebitMandate.Get("Direct Debit Mandate ID") then
                    if "Direct Debit Mandate Counter" = 0 then
                        "Sequence Type" := "Sequence Type"::" "
                    else
                        if SEPADirectDebitMandate."Type of Payment" = SEPADirectDebitMandate."Type of Payment"::OneOff then
                            "Sequence Type" := "Sequence Type"::OOFF
                        else
                            case "Direct Debit Mandate Counter" of
                                1:
                                    "Sequence Type" := "Sequence Type"::FRST;
                                SEPADirectDebitMandate."Expected Number of Debits":
                                    "Sequence Type" := "Sequence Type"::FNAL;
                                else
                                    "Sequence Type" := "Sequence Type"::RCUR;
                            end;
            end;
        }
        field(140; "Sequence Type"; Option)
        {
            Caption = 'Sequence Type';
            Editable = false;
            OptionCaption = ' ,OOFF,FRST,RCUR,FNAL', Locked = true;
            OptionMembers = " ",OOFF,FRST,RCUR,FNAL;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
        field(11400; "Foreign Currency"; Code[10])
        {
            Caption = 'Foreign Currency';
        }
        field(11401; "Foreign Amount"; Decimal)
        {
            Caption = 'Foreign Amount';
        }
        field(11402; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(11403; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
    }

    keys
    {
        key(Key1; "Our Bank", "Run No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount;
        }
        key(Key2; "Our Bank", Status, "Run No.", "Order", Date)
        {
            SumIndexFields = Amount;
        }
        key(Key3; "Document No.", "Posting Date")
        {
        }
        key(Key4; "Our Bank", "Run No.", "Payment/Receipt", Date)
        {
        }
        key(Key5; "Our Bank", Identification, Status)
        {
        }
        key(Key6; Date, "Sequence Type")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DetailLine: Record "Detail Line";
    begin
        if Status in [Status::New, Status::Transmitted, Status::"Request for Cancellation"] then
            Error(Text1000000 + Text1000001);

        FindRelatedDetailLines(DetailLine);
        DetailLine.DeleteAll(true);

        DeletePaymentFileErrors();
    end;

    var
        Text1000000: Label 'Entries with status "New", "Transmitted" or\';
        Text1000001: Label '"Request for cancellation" cannot be deleted.';
        PostCode: Record "Post Code";

    local procedure AddDocumentNoToList(var List: Text; DocumentNo: Code[35]; LenToCut: Integer)
    var
        Delimiter: Text[2];
        PrevLen: Integer;
    begin
        PrevLen := StrLen(List);
        if PrevLen <> 0 then
            Delimiter := ', ';
        List += Delimiter + DocumentNo;
        if (PrevLen <= LenToCut) and (StrLen(List) > LenToCut) then
            List := CopyStr(List, 1, PrevLen) + PadStr('', LenToCut - PrevLen) + CopyStr(List, PrevLen + StrLen(Delimiter) + 1);
    end;

    [Scope('OnPrem')]
    procedure GetAppliedDocNoList(LenToCut: Integer) List: Text
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DetailLine: Record "Detail Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmplLedgEntry: Record "Employee Ledger Entry";
        DocumentNo: Code[35];
    begin
        DetailLine.SetCurrentKey("Our Bank", Status, "Connect Batches", "Connect Lines", Date);
        DetailLine.SetRange("Our Bank", "Our Bank");
        DetailLine.SetFilter(Status, '%1|%2|%3', DetailLine.Status::"In process", DetailLine.Status::Posted, DetailLine.Status::Correction);
        DetailLine.SetRange("Connect Batches", "Run No.");
        DetailLine.SetRange("Connect Lines", "Line No.");
        if DetailLine.FindSet() then
            repeat
                case DetailLine."Account Type" of
                    DetailLine."Account Type"::Customer:
                        if CustLedgEntry.Get(DetailLine."Serial No. (Entry)") then
                            AddDocumentNoToList(List, CustLedgEntry."Document No.", LenToCut);
                    DetailLine."Account Type"::Vendor:
                        if VendLedgEntry.Get(DetailLine."Serial No. (Entry)") then begin
                            if VendLedgEntry."External Document No." = '' then
                                DocumentNo := VendLedgEntry."Document No."
                            else
                                DocumentNo := VendLedgEntry."External Document No.";
                            AddDocumentNoToList(List, DocumentNo, LenToCut);
                        end;
                    DetailLine."Account Type"::Employee:
                        if EmplLedgEntry.Get(DetailLine."Serial No. (Entry)") then
                            AddDocumentNoToList(List, EmplLedgEntry."Document No.", LenToCut);
                    else
                        exit('');
                end;
            until DetailLine.Next() = 0;
        exit(List);
    end;

    [Scope('OnPrem')]
    procedure DeletePaymentFileErrors()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.Reset();
        PaymentJnlExportErrorText.SetRange("Journal Template Name", '');
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", "Our Bank");
        PaymentJnlExportErrorText.SetRange("Document No.", "Run No.");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", "Line No.");
        PaymentJnlExportErrorText.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure WillBeSent()
    begin
        if Status = Status::New then begin
            Validate(Status, Status::Transmitted);
            Modify();
        end;
    end;

    [Obsolete('Replaced by GetSourceName', '15.4')]
    [Scope('OnPrem')]
    procedure NoSourceName() Name: Text[50]
    begin
        exit(CopyStr(GetSourceName(), 1, MaxStrLen(Name)));
    end;

    [Scope('OnPrem')]
    procedure GetSourceName() Name: Text
    var
        Custm: Record Customer;
        Vend: Record Vendor;
        Empl: Record Employee;
    begin
        if "Account No." <> '' then begin
            case "Account Type" of
                "Account Type"::Customer:
                    begin
                        Custm.Get("Account No.");
                        exit(Custm.Name);
                    end;
                "Account Type"::Vendor:
                    begin
                        Vend.Get("Account No.");
                        exit(Vend.Name);
                    end;
                "Account Type"::Employee:
                    begin
                        Empl.Get("Account No.");
                        exit(Empl.FullName());
                    end;
            end
        end else
            exit('');
    end;

    [Scope('OnPrem')]
    procedure GetAccHolderPostalAddr(var AddrLine: array[3] of Text[70]): Boolean
    begin
        Clear(AddrLine);
        AddrLine[1] := CopyStr(DelChr("Acc. Hold. Country/Region Code", '<>'), 1, 2);
        AddrLine[2] := CopyStr(DelChr("Account Holder Address", '<>'), 1, MaxStrLen(AddrLine[2]));
        AddrLine[3] :=
          CopyStr(DelChr(DelChr("Account Holder Post Code", '<>') + ' ' + DelChr("Account Holder City", '<>'), '<>'),
            1, MaxStrLen(AddrLine[3]));
        exit((AddrLine[1] + AddrLine[2] + AddrLine[3]) <> '');
    end;

    [Scope('OnPrem')]
    procedure GetUnstrRemitInfo() UnstrRemitInfo: Text[140]
    var
        DetailLine: Record "Detail Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        EmplLedgEntry: Record "Employee Ledger Entry";
        Delimiter: Text[2];
        IsHandled: Boolean;
    begin
        Delimiter := '';
        IsHandled := false;
        OnBeforeGetUnstrRemitInfo(Rec, UnstrRemitInfo, Delimiter, IsHandled);
        if IsHandled then
            exit;

        FindRelatedDetailLines(DetailLine);
        if DetailLine.IsEmpty() then
            exit("Description 1");

        if DetailLine.FindSet() then
            repeat
                case DetailLine."Account Type" of
                    DetailLine."Account Type"::Vendor:
                        if VendLedgEntry.Get(DetailLine."Serial No. (Entry)") then begin
                            if not AppendUnstrRemitInfo(UnstrRemitInfo, Delimiter, VendLedgEntry."External Document No.") then
                                exit;
                        end;
                    DetailLine."Account Type"::Customer:
                        if CustLedgEntry.Get(DetailLine."Serial No. (Entry)") then begin
                            if not AppendUnstrRemitInfo(UnstrRemitInfo, Delimiter, CustLedgEntry."Document No.") then
                                exit;
                        end;
                    DetailLine."Account Type"::Employee:
                        if EmplLedgEntry.Get(DetailLine."Serial No. (Entry)") then begin
                            if not AppendUnstrRemitInfo(UnstrRemitInfo, Delimiter, EmplLedgEntry."Document No.") then
                                exit;
                        end;
                end;
            until DetailLine.Next() = 0;

        OnAfterGetUnstrRemitInfo(Rec, DetailLine, UnstrRemitInfo);
    end;

    procedure AppendUnstrRemitInfo(var Info: Text[140]; var Delimiter: Text[2]; DocumentNo: Code[35]): Boolean
    var
        TempInfo: Text[250];
    begin
        TempInfo := Info + Delimiter + DocumentNo;
        Delimiter := ', ';
        if StrLen(TempInfo) > MaxStrLen(Info) then
            exit(false);
        Info := TempInfo;
        exit(true);
    end;

    local procedure FindRelatedDetailLines(var DetailLine: Record "Detail Line")
    begin
        DetailLine.Reset();
        DetailLine.SetCurrentKey("Our Bank", Status, "Connect Batches", "Connect Lines", Date);
        DetailLine.SetRange("Our Bank", "Our Bank");
        DetailLine.SetFilter(Status, '%1|%2|%3',
          DetailLine.Status::"In process", DetailLine.Status::Posted, DetailLine.Status::Correction);
        DetailLine.SetRange("Connect Batches", "Run No.");
        DetailLine.SetRange("Connect Lines", "Line No.");
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Line No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUnstrRemitInfo(var PaymentHistoryLine: Record "Payment History Line"; var DetailLine: Record "Detail Line"; var UnstrRemitInfo: Text[140])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnstrRemitInfo(var PaymentHistoryLine: Record "Payment History Line"; var UnstrRemitInfo: Text[140]; var Delimiter: Text[2]; var IsHandled: Boolean)
    begin
    end;
}

