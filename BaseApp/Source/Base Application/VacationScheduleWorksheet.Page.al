page 17492 "Vacation Schedule Worksheet"
{
    AutoSplitKey = true;
    Caption = 'Vacation Schedule Worksheet';
    PageType = Worksheet;
    SourceTable = "Vacation Schedule Line";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(CurrYear; CurrYear)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Year';
                    ToolTip = 'Specifies the year.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        VacationScheduleName: Record "Vacation Schedule Name";
                        VacationScheduleNames: Page "Vacation Schedule Names";
                    begin
                        if CurrYear <> 0 then begin
                            VacationScheduleName.Get(Year);
                            VacationScheduleNames.SetRecord(VacationScheduleName);
                        end;

                        VacationScheduleNames.LookupMode := true;
                        if VacationScheduleNames.RunModal = ACTION::LookupOK then begin
                            VacationScheduleNames.GetRecord(VacationScheduleName);
                            CurrYear := VacationScheduleName.Year;
                            SetFilters;
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        CurrYearOnAfterValidate;
                    end;
                }
                field(OrgUnitFilter; OrgUnitFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Org. Unit Filter';
                    TableRelation = "Organizational Unit";

                    trigger OnValidate()
                    begin
                        OrgUnitFilterOnAfterValidate;
                    end;
                }
            }
            repeater(Control1210001)
            {
                ShowCaption = false;
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Employee Name"; "Employee Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee Name';
                    Editable = false;
                }
                field("Org. Unit Code"; "Org. Unit Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Job Title Code"; "Job Title Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("Calendar Days"; "Calendar Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of calendar days.';
                }
                field("Actual Start Date"; "Actual Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the employee''s vacation.';
                }
                field("Carry Over Reason"; "Carry Over Reason")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Estimated Start Date"; "Estimated Start Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Comments; Comments)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Suggest Employees")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Employees';
                    Image = Employee;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    begin
                        SuggestEmployees(CurrYear);
                    end;
                }
            }
            group("P&rint")
            {
                Caption = 'P&rint';
                Image = Print;
                action("Vacation Schedule T-7")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vacation Schedule T-7';
                    Image = PrintDocument;

                    trigger OnAction()
                    var
                        VacationScheduleName: Record "Vacation Schedule Name";
                    begin
                        VacationScheduleName.SetRange(Year, Year);
                        REPORT.RunModal(REPORT::"Vacation Schedule T-7", true, true, VacationScheduleName);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if CurrYear = 0 then
            CurrYear := Date2DMY(WorkDate, 3);
        SetFilters;
    end;

    var
        CurrYear: Integer;
        OrgUnitFilter: Code[20];

    [Scope('OnPrem')]
    procedure SetVacationSchedule(NewYear: Integer)
    begin
        CurrYear := NewYear;
    end;

    local procedure SetFilters()
    begin
        FilterGroup(2);
        SetRange(Year, CurrYear);
        FilterGroup(0);
        if OrgUnitFilter <> '' then
            SetFilter("Org. Unit Code", OrgUnitFilter)
        else
            SetRange("Org. Unit Code");

        CurrPage.Update(false);
    end;

    local procedure OrgUnitFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord;
        SetFilters;
    end;

    local procedure CurrYearOnAfterValidate()
    begin
        CurrPage.SaveRecord;
        SetFilters;
    end;
}

