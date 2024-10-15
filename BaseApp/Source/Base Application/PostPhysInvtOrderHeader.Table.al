table 5005354 "Post. Phys. Invt. Order Header"
{
    Caption = 'Post. Phys. Invt. Order Header';
    DataCaptionFields = "No.", Description;
    ObsoleteReason = 'Merged to W1';
    ObsoleteState = Pending;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(10; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(11; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Open,Finished';
            OptionMembers = Open,Finished;
        }
        field(20; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(30; Comment; Boolean)
        {
            CalcFormula = Exist ("Phys. Inventory Comment Line" WHERE("Document Type" = CONST("Posted Order"),
                                                                      "Order No." = FIELD("No."),
                                                                      "Recording No." = CONST(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Person Responsible"; Code[20])
        {
            Caption = 'Person Responsible';
            TableRelation = Employee;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(40; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(41; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(50; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(51; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(60; "Pre-Assigned No. Series"; Code[20])
        {
            Caption = 'Pre-Assigned No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(61; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(62; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
        }
        field(63; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(66; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(71; "No. Finished Recordings"; Integer)
        {
            CalcFormula = Count ("Phys. Invt. Recording Header" WHERE("Order No." = FIELD("No."),
                                                                      Status = CONST(Finished)));
            Caption = 'No. Finished Recordings';
            Editable = false;
            FieldClass = FlowField;
        }
        field(110; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(111; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

