table 31049 "Credit Report Selections"
{
    Caption = 'Credit Report Selections';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Compensation Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; Usage; Option)
        {
            Caption = 'Usage';
            OptionCaption = 'Credit,Posted Credit';
            OptionMembers = Credit,"Posted Credit";
        }
        field(2; Sequence; Code[10])
        {
            Caption = 'Sequence';
            Numeric = true;
        }
        field(3; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Report));

            trigger OnValidate()
            begin
                CalcFields("Report Name");
            end;
        }
        field(4; "Report Name"; Text[80])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Report ID")));
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
        CreditReportSelections2: Record "Credit Report Selections";

    [Scope('OnPrem')]
    [Obsolete('Moved to Compensation Localization Pack for Czech.', '18.0')]
    procedure NewRecord()
    begin
        CreditReportSelections2.SetRange(Usage, Usage);
        if CreditReportSelections2.FindLast and (CreditReportSelections2.Sequence <> '') then
            Sequence := IncStr(CreditReportSelections2.Sequence)
        else
            Sequence := '1';
    end;
}

