page 17377 "Staff List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Staff';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Staff List";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Org. Unit Code", "Job Title Code");
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(ShowBudget; ShowBudget)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Budget/Actual';
                    OptionCaption = 'Actual,Budget,All';

                    trigger OnValidate()
                    begin
                        case ShowBudget of
                            ShowBudget::Actual:
                                SetRange("Budgeted Filter", false);
                            ShowBudget::Budget:
                                SetRange("Budgeted Filter", true);
                            ShowBudget::All:
                                SetRange("Budgeted Filter");
                        end;
                    end;
                }
                field(ShowStaff; ShowStaff)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Staff/Out-of-Staff';
                    OptionCaption = 'Staff Only,Out of Staff,All';

                    trigger OnValidate()
                    begin
                        case ShowStaff of
                            ShowStaff::"Staff Only":
                                SetRange("Out-of-Staff Filter", false);
                            ShowStaff::"Out of Staff":
                                SetRange("Out-of-Staff Filter", true);
                            ShowStaff::All:
                                SetRange("Out-of-Staff Filter");
                        end;
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View as';
                    OptionCaption = 'Net Change,Balance at Date';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                    end;
                }
            }
            repeater(Control1210001)
            {
                Editable = false;
                IndentationColumn = Indentation;
                IndentationControls = "Org. Unit Code";
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Org. Unit Code"; "Org. Unit Code")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = OrgUnitEmphasize;
                }
                field("Org. Unit Name"; "Org. Unit Name")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = OrgUnitEmphasize;
                }
                field("Job Title Code"; "Job Title Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Title Name"; "Job Title Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Planned Positions"; "Planned Positions")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Approved Positions"; "Approved Positions")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Closed Positions"; "Closed Positions")
                {
                    BlankZero = true;
                    Visible = false;
                }
                field("Planned Base Salary"; "Planned Base Salary")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Planned Additional Salary"; "Planned Additional Salary")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Planned Monthly Salary"; "Planned Monthly Salary")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Planned Budgeted Salary"; "Planned Budgeted Salary")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Approved Base Salary"; "Approved Base Salary")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Approved Additional Salary"; "Approved Additional Salary")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Approved Monthly Salary"; "Approved Monthly Salary")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Approved Budgeted Salary"; "Approved Budgeted Salary")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Previous Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Previous Period';

                trigger OnAction()
                begin
                    FindPeriod('<=');
                end;
            }
            action("Next Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Next Period';

                trigger OnAction()
                begin
                    FindPeriod('>=');
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Archive)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Archive';
                    Image = NewDocument;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        CreateArchive(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        OrgUnitOnFormat;
    end;

    trigger OnOpenPage()
    begin
        AmountType := AmountType::"Balance at Date";
        SetRange("Date Filter", 0D, WorkDate);
        SetRange("Budgeted Filter", false);
        SetRange("Out-of-Staff Filter", false);
        FindPeriod('');
    end;

    var
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";
        ShowBudget: Option Actual,Budget,All;
        ShowStaff: Option "Staff Only","Out of Staff",All;
        [InDataSet]
        OrgUnitEmphasize: Boolean;

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
    begin
        if GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", GetFilter("Date Filter"));
            if not PeriodFormMgt.FindDate('+', Calendar, PeriodType) then
                PeriodFormMgt.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodFormMgt.FindDate(SearchText, Calendar, PeriodType);
        if AmountType = AmountType::"Net Change" then
            if Calendar."Period Start" = Calendar."Period End" then
                SetRange("Date Filter", Calendar."Period Start")
            else
                SetRange("Date Filter", Calendar."Period Start", Calendar."Period End")
        else
            SetRange("Date Filter", 0D, Calendar."Period End");

        Create(Rec, GetRangeMin("Date Filter"), GetRangeMax("Date Filter"));
        Rec := xRec;
    end;

    local procedure OrgUnitOnFormat()
    begin
        OrgUnitEmphasize := Type = Type::Heading;
    end;
}

