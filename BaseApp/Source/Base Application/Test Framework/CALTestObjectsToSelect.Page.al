page 130407 "CAL Test Objects To Select"
{
    Caption = 'CAL Test Objects To Select';
    Editable = false;
    PageType = List;
    SourceTable = "Object";
    SourceTableView = WHERE(Type = FILTER(> TableData));
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced with the AL Test Objects To Select page';
    ObsoleteTag = '15.2';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = All;
                }
                field(ID; ID)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID that applies.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the test objects selected.';
                }
                field(HitBy; CountTestCodeunits)
                {
                    ApplicationArea = All;
                    Caption = 'Hit By Test Codeunits';

                    trigger OnDrillDown()
                    begin
                        if CALTestCoverageMap.FindFirst then
                            PAGE.RunModal(0, CALTestCoverageMap);
                    end;
                }
                field(Caption; Caption)
                {
                    ApplicationArea = All;
                    DrillDown = false;
                    Visible = false;
                }
                field(Modified; Modified)
                {
                    ApplicationArea = All;
                }
                field(Date; Date)
                {
                    ApplicationArea = All;
                }
                field(Time; Time)
                {
                    ApplicationArea = All;
                }
                field("Version List"; "Version List")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CALTestCoverageMap.SetRange("Object Type", Type);
        CALTestCoverageMap.SetRange("Object ID", ID);
    end;

    var
        CALTestCoverageMap: Record "CAL Test Coverage Map";

    local procedure CountTestCodeunits(): Integer
    begin
        if CALTestCoverageMap.FindFirst then begin
            CALTestCoverageMap.CalcFields("Hit by Test Codeunits");
            exit(CALTestCoverageMap."Hit by Test Codeunits");
        end;
        exit(0);
    end;
}

