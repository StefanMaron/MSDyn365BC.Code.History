table 7000013 "Cartera Report Selections"
{
    Caption = 'Cartera Report Selections';

    fields
    {
        field(1; Usage; Option)
        {
            Caption = 'Usage';
            OptionCaption = 'Bill Group,Posted Bill Group,Closed Bill Group,Bill,Bill Group - Test,Payment Order,Posted Payment Order,Payment Order - Test,Closed Payment Order';
            OptionMembers = "Bill Group","Posted Bill Group","Closed Bill Group",Bill,"Bill Group - Test","Payment Order","Posted Payment Order","Payment Order - Test","Closed Payment Order";
        }
        field(2; Sequence; Code[10])
        {
            Caption = 'Sequence';
            Numeric = true;
        }
        field(3; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));

            trigger OnValidate()
            begin
                CalcFields("Report Name");
            end;
        }
        field(4; "Report Name"; Text[30])
        {
            CalcFormula = Lookup (Object.Name WHERE(Type = CONST(Report),
                                                    ID = FIELD("Report ID")));
            Caption = 'Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Usage, Sequence)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CarteraReportSelection2: Record "Cartera Report Selections";

    [Scope('OnPrem')]
    procedure NewRecord()
    begin
        CarteraReportSelection2.SetRange(Usage, Usage);
        if CarteraReportSelection2.FindLast and (CarteraReportSelection2.Sequence <> '') then
            Sequence := IncStr(CarteraReportSelection2.Sequence)
        else
            Sequence := '1';
    end;
}

