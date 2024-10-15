page 17413 "Payroll Range Lines"
{
    AutoSplitKey = true;
    Caption = 'Payroll Range Lines';
    PageType = List;
    SourceTable = "Payroll Range Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Disabled Person"; "Disabled Person")
                {
                    ApplicationArea = All;
                    Visible = IsDisabledPersonVisible;
                }
                field(Student; Student)
                {
                    ApplicationArea = All;
                    Visible = IsStudentVisible;
                }
                field(Age; Age)
                {
                    ApplicationArea = All;
                    Visible = IsAgeVisible;
                }
                field("From Birthday and Younger"; "From Birthday and Younger")
                {
                    ApplicationArea = All;
                    Visible = IsFromBirthdayandYoungerVisible;
                }
                field("Employee Gender"; "Employee Gender")
                {
                    ApplicationArea = All;
                    Visible = IsEmployeeGenderVisible;
                }
                field("Over Amount"; "Over Amount")
                {
                    ApplicationArea = All;
                    Visible = IsOverAmountVisible;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount.';
                    Visible = IsAmountVisible;
                }
                field("Min Amount"; "Min Amount")
                {
                    ApplicationArea = All;
                    Visible = IsMinAmountVisible;
                }
                field("Max Amount"; "Max Amount")
                {
                    ApplicationArea = All;
                    Visible = IsMaxAmountVisible;
                }
                field("Max Deduction"; "Max Deduction")
                {
                    ApplicationArea = All;
                    Visible = IsMaxDeductionVisible;
                }
                field(Limit; Limit)
                {
                    ApplicationArea = All;
                    Visible = IsLimitVisible;
                }
                field("Tax %"; "Tax %")
                {
                    ApplicationArea = All;
                    Visible = IsTaxPercentVisible;
                }
                field("Tax Amount"; "Tax Amount")
                {
                    ApplicationArea = All;
                    Visible = IsTaxAmountVisible;
                }
                field(Percent; Percent)
                {
                    ApplicationArea = All;
                    Visible = IsPercentVisible;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many units of the record are processed.';
                    Visible = IsQuantityVisible;
                }
                field("On Allowance"; "On Allowance")
                {
                    ApplicationArea = All;
                    Visible = IsOnAllowanceVisible;
                }
                field("From Allowance"; "From Allowance")
                {
                    ApplicationArea = All;
                    Visible = IsFromAllowanceVisible;
                }
                field("Directory Code"; "Directory Code")
                {
                    ApplicationArea = All;
                    Visible = IsDirectoryCodeVisible;
                }
                field(RangeType; RangeType)
                {
                    ApplicationArea = All;
                    Caption = 'Range Type';
                    Visible = IsIncreaseWageVisible;
                }
                field("Coordination %"; "Coordination %")
                {
                    ApplicationArea = All;
                    Visible = IsCoordinationPercentVisible;
                }
                field("Max %"; "Max %")
                {
                    ApplicationArea = All;
                    Visible = IsMaxPercentVisible;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Range Type" := RangeType;
    end;

    trigger OnOpenPage()
    begin
        IsDirectoryCodeVisible := IfDirectoryCodeVisible;
        IsPercentVisible := IfPercentVisible;
        IsOverAmountVisible := IfOverAmountVisible;
        IsFromBirthdayandYoungerVisible := IfFromBirthdayandYoungerVisible;
        IsQuantityVisible := IfQuantityVisible;
        IsAmountVisible := IfAmountVisible;
        IsIncreaseWageVisible := IfIncreaseWageVisible;
        IsMaxAmountVisible := IfMaxAmountVisible;
        IsMinAmountVisible := IfMinAmountVisible;
        IsOnAllowanceVisible := IfOnAllowanceVisible;
        IsFromAllowanceVisible := IfFromAllowanceVisible;
        IsCoordinationPercentVisible := IfCoordinationPercentVisible;
        IsMaxPercentVisible := IfMaxPercentVisible;
        IsAgeVisible := IfAgeVisible;
        IsDisabledPersonVisible := IfDisabledPersonVisible;
        IsStudentVisible := IfStudentVisible;
        IsEmployeeGenderVisible := IfEmployeeGenderVisible;
        IsLimitVisible := IfLimitVisible;
        IsTaxPercentVisible := IfTaxPercentVisible;
        IsTaxAmountVisible := IfTaxAmountVisible;
        IsMaxDeductionVisible := IfMaxDeductionVisible;
    end;

    var
        RangeType: Option " ",Deduction,"Tax Deduction",Exclusion,"Deduct. Benefit","Tax Abatement","Limit + Tax %",Frequency,Coordination,"Increase Salary",Quantity;
        [InDataSet]
        IsDirectoryCodeVisible: Boolean;
        [InDataSet]
        IsPercentVisible: Boolean;
        [InDataSet]
        IsOverAmountVisible: Boolean;
        [InDataSet]
        IsFromBirthdayandYoungerVisible: Boolean;
        [InDataSet]
        IsQuantityVisible: Boolean;
        [InDataSet]
        IsAmountVisible: Boolean;
        [InDataSet]
        IsIncreaseWageVisible: Boolean;
        [InDataSet]
        IsMaxAmountVisible: Boolean;
        [InDataSet]
        IsMinAmountVisible: Boolean;
        [InDataSet]
        IsOnAllowanceVisible: Boolean;
        [InDataSet]
        IsFromAllowanceVisible: Boolean;
        [InDataSet]
        IsCoordinationPercentVisible: Boolean;
        [InDataSet]
        IsMaxPercentVisible: Boolean;
        [InDataSet]
        IsAgeVisible: Boolean;
        [InDataSet]
        IsDisabledPersonVisible: Boolean;
        [InDataSet]
        IsStudentVisible: Boolean;
        [InDataSet]
        IsEmployeeGenderVisible: Boolean;
        [InDataSet]
        IsLimitVisible: Boolean;
        [InDataSet]
        IsTaxPercentVisible: Boolean;
        [InDataSet]
        IsTaxAmountVisible: Boolean;
        [InDataSet]
        IsMaxDeductionVisible: Boolean;

    [Scope('OnPrem')]
    procedure Set(NewRangeType: Option)
    begin
        RangeType := NewRangeType;
    end;

    [Scope('OnPrem')]
    procedure IfDirectoryCodeVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Exclusion, RangeType::"Deduct. Benefit", RangeType::"Tax Abatement",
                             RangeType::"Limit + Tax %", RangeType::Coordination, RangeType::"Increase Salary",
                             RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfPercentVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Deduction, RangeType::"Tax Deduction", RangeType::"Deduct. Benefit",
                             RangeType::"Limit + Tax %", RangeType::Coordination, RangeType::"Increase Salary",
                             RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfOverAmountVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Exclusion, RangeType::"Limit + Tax %", RangeType::Coordination,
                             RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfFromBirthdayandYoungerVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::"Tax Deduction", RangeType::Exclusion, RangeType::"Deduct. Benefit",
                             RangeType::"Tax Abatement", RangeType::"Limit + Tax %", RangeType::Coordination,
                             RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfQuantityVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Deduction, RangeType::"Tax Deduction", RangeType::Exclusion,
                             RangeType::"Deduct. Benefit", RangeType::"Tax Abatement", RangeType::"Limit + Tax %",
                             RangeType::Coordination, RangeType::"Increase Salary"]));
    end;

    [Scope('OnPrem')]
    procedure IfAmountVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Deduction, RangeType::"Deduct. Benefit", RangeType::"Limit + Tax %",
                             RangeType::Coordination, RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfIncreaseWageVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Deduction, RangeType::"Tax Deduction", RangeType::Exclusion,
                            RangeType::"Deduct. Benefit", RangeType::"Tax Abatement", RangeType::"Limit + Tax %",
                            RangeType::Coordination, RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfMaxAmountVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Deduction, RangeType::"Deduct. Benefit", RangeType::"Deduct. Benefit",
                             RangeType::Coordination, RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfMinAmountVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Deduction, RangeType::"Deduct. Benefit", RangeType::"Limit + Tax %",
                             RangeType::Coordination, RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfOnAllowanceVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Deduction, RangeType::"Deduct. Benefit", RangeType::"Limit + Tax %",
                             RangeType::Coordination, RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfFromAllowanceVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Deduction, RangeType::"Tax Deduction", RangeType::"Deduct. Benefit",
                             RangeType::"Tax Abatement", RangeType::"Limit + Tax %", RangeType::Coordination,
                             RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfCoordinationPercentVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Deduction, RangeType::"Tax Deduction", RangeType::Exclusion,
                             RangeType::"Deduct. Benefit", RangeType::"Tax Abatement", RangeType::"Limit + Tax %",
                             RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfMaxPercentVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Deduction, RangeType::"Tax Deduction", RangeType::Exclusion,
                             RangeType::"Deduct. Benefit", RangeType::"Tax Abatement", RangeType::"Limit + Tax %",
                             RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfAgeVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Deduction, RangeType::Exclusion, RangeType::"Deduct. Benefit",
                             RangeType::"Tax Abatement", RangeType::"Limit + Tax %", RangeType::Coordination,
                             RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfDisabledPersonVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Deduction, RangeType::Exclusion, RangeType::"Deduct. Benefit",
                             RangeType::"Tax Abatement", RangeType::"Limit + Tax %", RangeType::Coordination,
                             RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfStudentVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::Deduction, RangeType::Exclusion, RangeType::"Deduct. Benefit",
                             RangeType::"Tax Abatement", RangeType::"Limit + Tax %", RangeType::Coordination,
                             RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfEmployeeGenderVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::"Tax Deduction", RangeType::Exclusion, RangeType::"Deduct. Benefit",
                             RangeType::"Tax Abatement", RangeType::"Limit + Tax %", RangeType::Coordination,
                             RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfLimitVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::"Tax Deduction", RangeType::"Tax Abatement", RangeType::Coordination,
                             RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfTaxPercentVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::"Tax Deduction", RangeType::Exclusion, RangeType::"Tax Abatement",
                             RangeType::Coordination, RangeType::"Increase Salary", RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfTaxAmountVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::"Tax Deduction", RangeType::Exclusion, RangeType::"Tax Abatement",
                             RangeType::"Limit + Tax %", RangeType::Coordination, RangeType::"Increase Salary",
                             RangeType::Quantity]));
    end;

    [Scope('OnPrem')]
    procedure IfMaxDeductionVisible(): Boolean
    begin
        exit(
          not (RangeType in [RangeType::"Tax Deduction", RangeType::Exclusion, RangeType::"Tax Abatement",
                             RangeType::"Limit + Tax %", RangeType::Coordination, RangeType::"Increase Salary",
                             RangeType::Quantity]));
    end;
}

