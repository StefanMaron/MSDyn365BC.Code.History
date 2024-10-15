table 31123 "EET Entry"
{
    Caption = 'EET Entry';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '21.0';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Cash Desk';
            OptionMembers = " ","Cash Desk";
        }
        field(12; "Source No."; Code[20])
        {
            Caption = 'Source No.';
        }
        field(20; "Business Premises Code"; Code[10])
        {
            Caption = 'Business Premises Code';
            NotBlank = true;
        }
        field(25; "Cash Register Code"; Code[10])
        {
            Caption = 'Cash Register Code';
            NotBlank = true;
        }
        field(30; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(40; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(50; "Applied Document Type"; Option)
        {
            Caption = 'Applied Document Type';
            OptionCaption = ' ,Invoice,Credit Memo,Prepayment';
            OptionMembers = " ",Invoice,"Credit Memo",Prepayment;
        }
        field(55; "Applied Document No."; Code[20])
        {
            Caption = 'Applied Document No.';
        }
        field(60; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(62; "Creation Datetime"; DateTime)
        {
            Caption = 'Creation Datetime';
        }
        field(70; "EET Status"; Option)
        {
            Caption = 'EET Status';
            OptionCaption = 'Created,Send Pending,Sent,Failure,Success,Success with Warnings,Sent to Verification,Verified,Verified with Warnings';
            OptionMembers = Created,"Send Pending",Sent,Failure,Success,"Success with Warnings","Sent to Verification",Verified,"Verified with Warnings";
        }
        field(72; "EET Status Last Changed"; DateTime)
        {
            Caption = 'EET Status Last Changed';
        }
        field(75; "Message UUID"; Text[36])
        {
            Caption = 'Message UUID';
        }
        field(76; "Signature Code (PKP)"; BLOB)
        {
            Caption = 'Signature Code (PKP)';
        }
        field(77; "Security Code (BKP)"; Text[44])
        {
            Caption = 'Security Code (BKP)';
        }
        field(78; "Fiscal Identification Code"; Text[39])
        {
            Caption = 'Fiscal Identification Code';
        }
        field(85; "Receipt Serial No."; Code[50])
        {
            Caption = 'Receipt Serial No.';
        }
        field(150; "Total Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Sales Amount';
        }
        field(155; "Amount Exempted From VAT"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount Exempted From VAT';
        }
        field(160; "VAT Base (Basic)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base (Basic)';
            Editable = false;
        }
        field(161; "VAT Amount (Basic)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (Basic)';
        }
        field(164; "VAT Base (Reduced)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base (Reduced)';
            Editable = false;
        }
        field(165; "VAT Amount (Reduced)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (Reduced)';
        }
        field(167; "VAT Base (Reduced 2)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base (Reduced 2)';
            Editable = false;
        }
        field(168; "VAT Amount (Reduced 2)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (Reduced 2)';
        }
        field(170; "Amount - Art.89"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount - Art.89';
        }
        field(175; "Amount (Basic) - Art.90"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (Basic) - Art.90';
        }
        field(177; "Amount (Reduced) - Art.90"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (Reduced) - Art.90';
        }
        field(179; "Amount (Reduced 2) - Art.90"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (Reduced 2) - Art.90';
        }
        field(190; "Amt. For Subseq. Draw/Settle"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amt. For Subseq. Draw/Settle';
        }
        field(195; "Amt. Subseq. Drawn/Settled"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amt. Subseq. Drawn/Settled';
        }
        field(200; "Canceled By Entry No."; Integer)
        {
            Caption = 'Canceled By Entry No.';
        }
        field(210; "Simple Registration"; Boolean)
        {
            Caption = 'Simple Registration';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Business Premises Code", "Cash Register Code")
        {
        }
        key(Key3; "EET Status")
        {
        }
        key(Key4; "Document No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;
}