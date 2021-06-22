table 5769 "Warehouse Setup"
{
    Caption = 'Warehouse Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Whse. Receipt Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Receipt Header" = R;
            Caption = 'Whse. Receipt Nos.';
            TableRelation = "No. Series";
        }
        field(3; "Whse. Put-away Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
            Caption = 'Whse. Put-away Nos.';
            TableRelation = "No. Series";
        }
        field(5; "Whse. Pick Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Pick Header" = R;
            Caption = 'Whse. Pick Nos.';
            TableRelation = "No. Series";
        }
        field(6; "Whse. Ship Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Shipment Header" = R;
            Caption = 'Whse. Ship Nos.';
            TableRelation = "No. Series";
        }
        field(7; "Registered Whse. Pick Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Pick Header" = R;
            Caption = 'Registered Whse. Pick Nos.';
            TableRelation = "No. Series";
        }
        field(10; "Registered Whse. Put-away Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
            Caption = 'Registered Whse. Put-away Nos.';
            TableRelation = "No. Series";
        }
        field(13; "Require Receive"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Receipt Header" = R;
            Caption = 'Require Receive';

            trigger OnValidate()
            begin
                if not "Require Receive" then
                    "Require Put-away" := false;
            end;
        }
        field(14; "Require Put-away"; Boolean)
        {
            AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
            Caption = 'Require Put-away';

            trigger OnValidate()
            begin
                if "Require Put-away" then
                    "Require Receive" := true;
            end;
        }
        field(15; "Require Pick"; Boolean)
        {
            AccessByPermission = TableData "Posted Invt. Pick Header" = R;
            Caption = 'Require Pick';

            trigger OnValidate()
            begin
                if "Require Pick" then
                    "Require Shipment" := true;
            end;
        }
        field(16; "Require Shipment"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Shipment Header" = R;
            Caption = 'Require Shipment';

            trigger OnValidate()
            begin
                if not "Require Shipment" then
                    "Require Pick" := false;
            end;
        }
        field(17; "Last Whse. Posting Ref. No."; Integer)
        {
            Caption = 'Last Whse. Posting Ref. No.';
            Editable = false;
        }
        field(18; "Receipt Posting Policy"; Option)
        {
            Caption = 'Receipt Posting Policy';
            OptionCaption = 'Posting errors are not processed,Stop and show the first posting error';
            OptionMembers = "Posting errors are not processed","Stop and show the first posting error";
        }
        field(19; "Shipment Posting Policy"; Option)
        {
            Caption = 'Shipment Posting Policy';
            OptionCaption = 'Posting errors are not processed,Stop and show the first posting error';
            OptionMembers = "Posting errors are not processed","Stop and show the first posting error";
        }
        field(7301; "Posted Whse. Receipt Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Receipt Header" = R;
            Caption = 'Posted Whse. Receipt Nos.';
            TableRelation = "No. Series";
        }
        field(7303; "Posted Whse. Shipment Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Shipment Header" = R;
            Caption = 'Posted Whse. Shipment Nos.';
            TableRelation = "No. Series";
        }
        field(7304; "Whse. Internal Put-away Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Whse. Internal Put-away Nos.';
            TableRelation = "No. Series";
        }
        field(7306; "Whse. Internal Pick Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Whse. Internal Pick Nos.';
            TableRelation = "No. Series";
        }
        field(7308; "Whse. Movement Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Whse. Movement Nos.';
            TableRelation = "No. Series";
        }
        field(7309; "Registered Whse. Movement Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Registered Whse. Movement Nos.';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetNextReference(): Integer
    begin
        LockTable();
        Get;
        "Last Whse. Posting Ref. No." := "Last Whse. Posting Ref. No." + 1;
        Modify;
        exit("Last Whse. Posting Ref. No.");
    end;
}

