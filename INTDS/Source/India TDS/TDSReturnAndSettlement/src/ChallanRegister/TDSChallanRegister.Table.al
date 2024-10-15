table 18749 "TDS Challan Register"
{
    Caption = 'TDS Challan Register';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Challan No."; Code[20])
        {
            Caption = 'Challan No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Challan Date"; Date)
        {
            Caption = 'Challan Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "BSR Code"; Code[20])
        {
            Caption = 'BSR Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "TDS Interest Amount"; Decimal)
        {
            Caption = 'TDS Interest Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(7; "TDS Others"; Decimal)
        {
            Caption = 'TDS Others';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(8; "Paid By Book Entry"; Boolean)
        {
            Caption = 'Paid By Book Entry';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(9; "Pay TDS Document No."; Code[20])
        {
            Caption = 'Pay TDS Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "Total TDS Amount"; Decimal)
        {
            Caption = 'Total TDS Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(11; "Total Surcharge Amount"; Decimal)
        {
            Caption = 'Total Surcharge Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(12; "Total eCess Amount"; Decimal)
        {
            Caption = 'Total eCess Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(13; "Total Invoice Amount"; Decimal)
        {
            Caption = 'Total Invoice Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(14; "Total TDS Including SHE Cess"; Decimal)
        {
            Caption = 'Total TDS Including SHE Cess';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(15; "TDS Payment Date"; Date)
        {
            Caption = 'TDS Payment Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "Non Resident Payment"; Boolean)
        {
            Caption = 'Non Resident Payment';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(17; "T.A.N. No."; Code[20])
        {
            Caption = 'T.A.N. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18; "TDS Section"; Code[10])
        {
            Caption = 'TDS Section';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(19; "Check / DD No."; Code[10])
        {
            Caption = 'Check / DD No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(20; "Check / DD Date"; Date)
        {
            Caption = 'Check / DD Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(21; Remarks; Text[30])
        {
            Caption = 'Remarks';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(22; "Batch No."; Integer)
        {
            Caption = 'Batch No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "Challan-Detail Record No."; Integer)
        {
            Caption = 'Challan-Detail Record No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(24; "Last Bank Challan No."; Code[20])
        {
            Caption = 'Last Bank Challan No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(25; "Last Bank-Branch Code"; Code[20])
        {
            Caption = 'Last Bank-Branch Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(26; "Last Date of Challan No."; Date)
        {
            Caption = 'Last Date of Challan No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(27; "Oltas TDS Income Tax"; Decimal)
        {
            Caption = 'Oltas TDS Income Tax';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(28; "Oltas TDS Surcharge"; Decimal)
        {
            Caption = 'Oltas TDS Surcharge';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(29; "Oltas TDS Cess"; Decimal)
        {
            Caption = 'Oltas TDS Cess';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; "Oltas Interest"; Decimal)
        {
            Caption = 'Oltas Interest';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(31; "Oltas Others"; Decimal)
        {
            Caption = 'Oltas Others';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(32; "Total Deposit Amt/Challan"; Decimal)
        {
            Caption = 'Total Deposit Amt/Challan';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(33; "Last Tot Deposit Amt/ Challan"; Decimal)
        {
            Caption = 'Last Tot Deposit Amt/ Challan';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(34; "Tot Tax Deposit Amt as Annx"; Decimal)
        {
            Caption = 'Tot Tax Deposit Amt as Annx';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(35; "Last TDS Others"; Decimal)
        {
            Caption = 'Last TDS Others';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(36; "Last TDS Interest"; Decimal)
        {
            Caption = 'Last TDS Interest';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(37; "Correction-C2"; Boolean)
        {
            Caption = 'Correction-C2';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(38; "Correction-C3"; Boolean)
        {
            Caption = 'Correction-C3';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(39; "Correction-C5"; Boolean)
        {
            Caption = 'Correction-C5';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(40; "Correction-C9"; Boolean)
        {
            Caption = 'Correction-C9';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(41; "Correction-Y"; Boolean)
        {
            Caption = 'Correction-Y';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(42; Filed; Boolean)
        {
            Caption = 'Filed';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(43; Revised; Boolean)
        {
            Caption = 'Revised';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(44; "Filing Date"; Date)
        {
            Caption = 'Filing Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(45; "Financial Year"; Code[9])
        {
            Caption = 'Financial Year';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(46; "Assessment Year"; Code[9])
        {
            Caption = 'Assessment Year';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(47; Quarter; Code[10])
        {
            Caption = 'Quarter';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(48; "Filing Date of Revised e-TDS"; Date)
        {
            Caption = 'Filing Date of Revised e-TDS';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(49; "No. of Revision"; Integer)
        {
            Caption = 'No. of Revision';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(50; "Nil Challan Indicator"; Boolean)
        {
            Caption = 'Nil Challan Indicator';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(51; "Challan Updation Indicator"; Integer)
        {
            Caption = 'Challan Updation Indicator';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(52; "Last Transfer Voucher No."; Code[20])
        {
            Caption = 'Last Transfer Voucher No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(53; "Transfer Voucher No."; Code[9])
        {
            Caption = 'Transfer Voucher No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(54; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";

            trigger OnLookup()
            begin
                LookupUserID("User ID");
            end;
        }
        field(55; "Normal eTDS Generated"; Boolean)
        {
            Caption = 'Normal eTDS Generated';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(56; "Revised eTDS Generated"; Boolean)
        {
            Caption = 'Revised eTDS Generated';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(57; "Total SHE Cess Amount"; Decimal)
        {
            Caption = 'Total SHE Cess Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(58; "Oltas TDS SHE Cess"; Decimal)
        {
            Caption = 'Oltas TDS SHE Cess';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(59; "Minor Head Code"; Enum "Minor Head Type")
        {
            Caption = 'Minor Head Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(60; "TDS Fee"; Decimal)
        {
            Caption = 'TDS Fee';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }
    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Quarter, "Financial Year")
        {
        }
    }
    procedure LookupUserID(VAR UserName: Code[50])
    var
        SID: Guid;
    begin
        LookupUser(UserName, SID);
    end;

    local procedure LookupUser(VAR UserName: Code[50]; VAR SID: GUID): Boolean
    var
        User: Record User;
    begin
        User.SetCurrentKey("User Name");
        User."User Name" := UserName;
        if User.Find('=><') then;
        if Page.RunModal(Page::Users, User) = Action::LookupOK then begin
            UserName := User."User Name";
            SID := User."User Security ID";
            exit(true)
        end;
        exit(false);
    end;
}