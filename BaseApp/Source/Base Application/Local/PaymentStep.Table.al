table 10862 "Payment Step"
{
    Caption = 'Payment Step';
    LookupPageID = "Payment Steps List";

    fields
    {
        field(1; "Payment Class"; Text[30])
        {
            Caption = 'Payment Class';
            TableRelation = "Payment Class";
        }
        field(2; Line; Integer)
        {
            Caption = 'Line';
        }
        field(3; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(4; "Previous Status"; Integer)
        {
            Caption = 'Previous Status';
            TableRelation = "Payment Status".Line WHERE("Payment Class" = FIELD("Payment Class"));
        }
        field(5; "Next Status"; Integer)
        {
            Caption = 'Next Status';
            TableRelation = "Payment Status".Line WHERE("Payment Class" = FIELD("Payment Class"));
        }
        field(6; "Action Type"; Enum "Payment Step Action Type")
        {
            Caption = 'Action Type';
        }
        field(7; "Report No."; Integer)
        {
            Caption = 'Report No.';
            TableRelation = IF ("Action Type" = CONST(Report)) AllObj."Object ID" WHERE("Object Type" = CONST(Report));
        }
        field(8; "Export No."; Integer)
        {
            Caption = 'Export No.';
            TableRelation = IF ("Action Type" = CONST(File),
                                "Export Type" = CONST(Report)) AllObj."Object ID" WHERE("Object Type" = CONST(Report))
            ELSE
            IF ("Action Type" = CONST(File),
                                         "Export Type" = CONST(XMLport)) AllObj."Object ID" WHERE("Object Type" = CONST(XMLport));
        }
        field(9; "Previous Status Name"; Text[50])
        {
            CalcFormula = Lookup("Payment Status".Name WHERE("Payment Class" = FIELD("Payment Class"),
                                                              Line = FIELD("Previous Status")));
            Caption = 'Previous Status Name';
            FieldClass = FlowField;
        }
        field(10; "Next Status Name"; Text[50])
        {
            CalcFormula = Lookup("Payment Status".Name WHERE("Payment Class" = FIELD("Payment Class"),
                                                              Line = FIELD("Next Status")));
            Caption = 'Next Status Name';
            FieldClass = FlowField;
        }
        field(11; "Verify Lines RIB"; Boolean)
        {
            Caption = 'Verify Lines RIB';
        }
        field(12; "Header Nos. Series"; Code[20])
        {
            Caption = 'Header Nos. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            var
                NoSeriesLine: Record "No. Series Line";
            begin
                if "Header Nos. Series" <> '' then begin
                    NoSeriesLine.SetRange("Series Code", "Header Nos. Series");
                    if NoSeriesLine.FindLast() then
                        if (StrLen(NoSeriesLine."Starting No.") > 10) or (StrLen(NoSeriesLine."Ending No.") > 10) then
                            Error(Text001);
                end;
            end;
        }
        field(13; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(14; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = true;
            TableRelation = "Source Code";
        }
        field(15; "Acceptation Code<>No"; Boolean)
        {
            Caption = 'Acceptation Code<>No';
        }
        field(16; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(17; "Verify Header RIB"; Boolean)
        {
            Caption = 'Verify Header RIB';
        }
        field(18; "Verify Due Date"; Boolean)
        {
            Caption = 'Verify Due Date';
        }
        field(19; "Realize VAT"; Boolean)
        {
            Caption = 'Realize VAT';
        }
        field(30; "Export Type"; Option)
        {
            Caption = 'Export Type';
            InitValue = "XMLport";
            OptionCaption = ',,,Report,,,XMLport';
            OptionMembers = ,,,"Report",,,"XMLport";

            trigger OnValidate()
            begin
                "Export No." := 0;
            end;
        }
    }

    keys
    {
        key(Key1; "Payment Class", Line)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if Line = 0 then
            Error(Text000);
    end;

    var
        Text000: Label 'Deleting the default report is not allowed.';
        Text001: Label 'You cannot assign a number series with numbers longer than 10 characters.';
}

