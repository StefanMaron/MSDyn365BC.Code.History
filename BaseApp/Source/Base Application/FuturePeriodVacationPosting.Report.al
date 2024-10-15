report 17420 "Future Period Vacation Posting"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Future Period Vacation Posting';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Employee; Employee)
        {
            RequestFilterFields = "No.", "Org. Unit Code";
            dataitem("Payroll Ledger Entry"; "Payroll Ledger Entry")
            {
                DataItemLink = "Employee No." = FIELD("No.");
                DataItemTableView = SORTING("Employee No.", "Period Code", "Element Code") WHERE("Document Type" = CONST(Vacation));

                trigger OnAfterGetRecord()
                begin
                    if "Action Start Date" > "Posting Date" then begin
                        PayrollPostingGroup.Get("Posting Group");
                        PayrollPostingGroup.TestField("Future Vacation G/L Acc. No.");
                        PayrollPostingGroup.TestField("Account No.");

                        GenJnlLine.Init();
                        GenJnlLine."Document No." := "Document No.";
                        GenJnlLine.Validate("Posting Date", PayrollPeriod."Ending Date");
                        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                        GenJnlLine.Validate("Account No.", PayrollPostingGroup."Future Vacation G/L Acc. No.");
                        case PayrollPostingGroup."Account Type" of
                            PayrollPostingGroup."Account Type"::"G/L Account":
                                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
                            PayrollPostingGroup."Account Type"::Vendor:
                                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::Vendor;
                        end;
                        GenJnlLine.Validate("Bal. Account No.", PayrollPostingGroup."Account No.");
                        GenJnlLine.Description :=
                          CopyStr(
                            StrSubstNo(
                              Text002,
                              Format(PayrollPeriod."Ending Date", 0, '<Month Text>'),
                              Employee.GetNameInitials),
                            1,
                            MaxStrLen(GenJnlLine.Description));
                        GenJnlLine.Validate(Amount, "Payroll Amount");
                        GenJnlLine."Payroll Ledger Entry No." := "Entry No.";
                        GenJnlLine."Dimension Set ID" := "Dimension Set ID";

                        GenJnlPostLine.RunWithCheck(GenJnlLine);

                        "Future Period Vacation Posted" := true;
                        Modify;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Action Start Date", '%1..%2', PayrollPeriod."Starting Date", PayrollPeriod."Ending Date");
                    SetRange("Future Period Vacation Posted", false);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Person.Get("Person No.");
                Person.TestField("Vendor No.");
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PeriodCode; PeriodCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payroll Period';
                        TableRelation = "Payroll Period";

                        trigger OnValidate()
                        begin
                            PeriodCodeOnAfterValidate;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if HiddenPeriodCode <> '' then
                PeriodCode := HiddenPeriodCode
            else
                PeriodCode := PeriodByDate(WorkDate);
        end;
    }

    labels
    {
    }

    var
        Person: Record Person;
        GenJnlLine: Record "Gen. Journal Line";
        PayrollPeriod: Record "Payroll Period";
        PayrollPostingGroup: Record "Payroll Posting Group";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PeriodCode: Code[10];
        Text002: Label 'Vacation pay write-off for %1 %2';
        HiddenPeriodCode: Code[10];

    [Scope('OnPrem')]
    procedure PeriodByDate(Date: Date): Code[10]
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        PayrollPeriod.Reset();
        PayrollPeriod.SetFilter("Ending Date", '%1..', Date);
        if PayrollPeriod.FindFirst then
            if PayrollPeriod."Starting Date" <= Date then
                exit(PayrollPeriod.Code);

        exit('');
    end;

    [Scope('OnPrem')]
    procedure SetPeriod(NewPeriodCode: Code[10])
    begin
        HiddenPeriodCode := NewPeriodCode;
        PayrollPeriod.Get(NewPeriodCode);
    end;

    local procedure PeriodCodeOnAfterValidate()
    begin
        PayrollPeriod.Get(PeriodCode);
    end;
}

