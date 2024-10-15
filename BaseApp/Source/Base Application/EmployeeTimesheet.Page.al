page 17441 "Employee Timesheet"
{
    Caption = 'Employee Timesheet';
    DataCaptionExpression = FormCaption;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Timesheet Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrPeriodCode; CurrPeriodCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Code';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord;
                        TimesheetMgt.LookupName(EmployeeNo, CurrPeriodCode, Rec);
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        PayrollPeriod.Get(CurrPeriodCode);
                        TimesheetStatus.Get(CurrPeriodCode, EmployeeNo);
                        CurrPeriodCodeOnAfterValidate;
                    end;
                }
                field(TimeActivityGroupFilter; TimeActivityGroupFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Time Activity Group';
                    TableRelation = "Time Activity Group";

                    trigger OnValidate()
                    begin
                        TimeActivityGroupFilterOnAfter;
                    end;
                }
            }
            repeater(Control1210000)
            {
                Editable = false;
                ShowCaption = false;
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Day; Day)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Org. Unit Code"; "Org. Unit Code")
                {
                    Visible = false;
                }
                field("Calendar Code"; "Calendar Code")
                {
                    ToolTip = 'Specifies the related work calendar. ';
                    Visible = false;
                }
                field(Nonworking; Nonworking)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(PlannedHours; PlannedHours)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Planned Hours';
                }
                field("Planned Night Hours"; "Planned Night Hours")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(ActualHours; ActualHours)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Actual Hours';

                    trigger OnAssistEdit()
                    begin
                        ActualAssistEdit;
                        CurrPage.Update();
                    end;
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
                action("Copy Details")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Details';
                    Image = Copy;

                    trigger OnAction()
                    begin
                        CopyDate := 0D;
                        if Confirm(Text001, true, Date) then
                            CopyDate := Date;
                    end;
                }
                action("Paste Details")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Paste Details';
                    Image = Insert;

                    trigger OnAction()
                    var
                        TimesheetDetailFrom: Record "Timesheet Detail";
                    begin
                        if CopyDate <> 0D then begin
                            TimesheetDetailFrom.SetRange("Employee No.", "Employee No.");
                            TimesheetDetailFrom.SetRange(Date, CopyDate);

                            CurrPage.SetSelectionFilter(TimesheetLine);
                            if TimesheetLine.FindSet then
                                repeat
                                    TimesheetDetail.SetRange("Employee No.", TimesheetLine."Employee No.");
                                    TimesheetDetail.SetRange(Date, TimesheetLine.Date);
                                    TimesheetDetail.DeleteAll(true);
                                    if TimesheetDetailFrom.FindSet then
                                        repeat
                                            TimesheetDetail.Init();
                                            TimesheetDetail := TimesheetDetailFrom;
                                            TimesheetDetail.Date := TimesheetLine.Date;
                                            TimesheetDetail."Document Type" := 0;
                                            TimesheetDetail."Document No." := '';
                                            TimesheetDetail."Document Date" := 0D;
                                            TimesheetDetail."User ID" := UserId;
                                            TimesheetDetail.Insert();
                                        until TimesheetDetailFrom.Next() = 0;
                                until TimesheetLine.Next() = 0;
                        end;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PlannedHours := StrSubstNo('%1 / %2  ', "Time Activity Code", "Planned Hours");

        ActualHours := '';
        TimesheetDetail.Reset();
        TimesheetDetail.SetRange("Employee No.", "Employee No.");
        TimesheetDetail.SetRange(Date, Date);
        if TimeActivityGroupFilter <> '' then begin
            TimesheetMgt.GetTimeGroupFilter(TimeActivityGroupFilter, Date, TimeActivityFilter);
            if TimeActivityFilter."Activity Code Filter" <> '' then
                TimesheetDetail.SetFilter("Time Activity Code", TimeActivityFilter."Activity Code Filter");
        end;
        if TimesheetDetail.FindSet then
            repeat
                ActualHours := ActualHours +
                  StrSubstNo('%1 / %2  ', TimesheetDetail."Time Activity Code", TimesheetDetail."Actual Hours");
            until TimesheetDetail.Next() = 0;
        DateOnFormat;
        DescriptionOnFormat;
    end;

    trigger OnOpenPage()
    begin
        if CurrPeriodCode = '' then
            if not TimesheetMgt.TimesheetSelection(CurrPeriodCode) then
                Error('');

        PayrollPeriod.Get(CurrPeriodCode);
        TimesheetMgt.SetName(EmployeeNo, PayrollPeriod, Rec);
    end;

    var
        PayrollPeriod: Record "Payroll Period";
        TimesheetStatus: Record "Timesheet Status";
        TimesheetLine: Record "Timesheet Line";
        TimesheetDetail: Record "Timesheet Detail";
        TimeActivityFilter: Record "Time Activity Filter";
        TimesheetMgt: Codeunit "Timesheet Management RU";
        CurrPeriodCode: Code[10];
        TimeActivityGroupFilter: Code[20];
        EmployeeNo: Code[20];
        ActualHours: Text[30];
        PlannedHours: Text[30];
        Text001: Label 'Copy timesheet details for %1 to the pasteboard?';
        CopyDate: Date;

    [Scope('OnPrem')]
    procedure Set(NewEmployeeNo: Code[20]; NewDate: Date)
    begin
        EmployeeNo := NewEmployeeNo;

        if NewDate = 0D then begin
            TimesheetStatus.Reset();
            TimesheetStatus.SetRange("Employee No.", NewEmployeeNo);
            TimesheetStatus.SetRange(Status, TimesheetStatus.Status::Open);
            if TimesheetStatus.FindFirst then
                CurrPeriodCode := TimesheetStatus."Period Code"
            else
                CurrPeriodCode := '';
        end else
            CurrPeriodCode := PayrollPeriod.PeriodByDate(NewDate);
    end;

    [Scope('OnPrem')]
    procedure FormCaption(): Text[250]
    var
        Employee: Record Employee;
    begin
        if Employee.Get(EmployeeNo) then
            exit(Employee."No." + ' ' + Employee.GetFullNameOnDate(PayrollPeriod."Starting Date"));

        exit(EmployeeNo);
    end;

    local procedure CurrPeriodCodeOnAfterValidate()
    begin
        CurrPage.SaveRecord;
        TimesheetMgt.SetName(EmployeeNo, PayrollPeriod, Rec);
        CurrPage.Update();
    end;

    local procedure TimeActivityGroupFilterOnAfter()
    begin
        CurrPage.Update();
    end;

    local procedure DateOnFormat()
    begin
        if Nonworking then;
    end;

    local procedure DescriptionOnFormat()
    begin
        if Nonworking then;
    end;
}

