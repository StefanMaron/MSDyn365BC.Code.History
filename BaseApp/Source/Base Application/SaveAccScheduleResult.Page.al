page 31087 "Save Acc. Schedule Result"
{
    Caption = 'Save Acc. Schedule Result';
    PageType = Card;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(AccSchedName; AccSchedName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Acc. Schedule Name';
                    Lookup = true;
                    TableRelation = "Acc. Schedule Name";
                    ToolTip = 'Specifies the name of account schedule.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(AccSchedMgt.LookupName(AccSchedName, Text));
                    end;

                    trigger OnValidate()
                    begin
                        UpdateColumnLayoutName;
                    end;
                }
                field(ColumnLayoutName; ColumnLayoutName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column Layout Name';
                    Lookup = true;
                    TableRelation = "Column Layout Name".Name;
                    ToolTip = 'Specifies the name of the column layout that you want to use in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(AccSchedMgt.LookupColumnName(ColumnLayoutName, Text));
                    end;

                    trigger OnValidate()
                    begin
                        AccSchedMgt.CheckColumnName(ColumnLayoutName);
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the date filter for G/L accounts entries.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        AccScheduleLine.SetFilter("Date Filter", DateFilter);
                        DateFilter := AccScheduleLine.GetFilter("Date Filter");
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of account schedule result.';
                }
                field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Amounts in Add. Reporting Currency';
                    MultiLine = true;
                    ToolTip = 'Specifies when the amounts in add. reporting currency is to be show';
                }
            }
        }
    }

    actions
    {
    }

    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccSchedMgt: Codeunit AccSchedManagement;
        AccSchedName: Code[10];
        ColumnLayoutName: Code[10];
        DateFilter: Text[30];
        Description: Text[50];
        UseAmtsInAddCurr: Boolean;

    [Scope('OnPrem')]
    procedure UpdateColumnLayoutName()
    begin
        AccSchedMgt.CheckName(AccSchedName);
        AccScheduleName.Get(AccSchedName);
        if AccScheduleName."Default Column Layout" <> '' then
            ColumnLayoutName := AccScheduleName."Default Column Layout";
    end;

    [Scope('OnPrem')]
    procedure SetParameters(NewAccSchedName: Code[10]; NewColumnLayoutName: Code[10]; NewDateFilter: Text[30]; NewUseAmtsInAddCurr: Boolean)
    begin
        AccSchedName := NewAccSchedName;
        if NewColumnLayoutName = '' then
            UpdateColumnLayoutName
        else
            ColumnLayoutName := NewColumnLayoutName;
        DateFilter := NewDateFilter;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
    end;

    [Scope('OnPrem')]
    procedure GetParameters(var NewAccSchedName: Code[10]; var NewColumnLayoutName: Code[10]; var NewDateFilter: Text[30]; var NewDescription: Text[50]; var NewUseAmtsInAddCurr: Boolean)
    begin
        NewAccSchedName := AccSchedName;
        NewColumnLayoutName := ColumnLayoutName;
        NewDateFilter := DateFilter;
        NewDescription := Description;
        NewUseAmtsInAddCurr := UseAmtsInAddCurr;
    end;
}

