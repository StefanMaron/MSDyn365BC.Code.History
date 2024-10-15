report 17410 "Suggest Salary Setup Lines"
{
    Caption = 'Suggest Salary Setup Lines';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Employee; Employee)
        {
            RequestFilterFields = "No.", "Org. Unit Code", "Last Name";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, Employee."No.");

                EmplJnlLine2.Init();
                EmplJnlLine2."Journal Template Name" := EmplJnlLine."Journal Template Name";
                EmplJnlLine2."Journal Batch Name" := EmplJnlLine."Journal Batch Name";
                EmplJnlLine2."Line No." := LineNo;
                EmplJnlLine2.Validate("Employee No.", "No.");
                EmplJnlLine2.Validate("Element Code", ElementCode);
                EmplJnlLine2.Validate("Posting Date", PostingDate);
                EmplJnlLine2.Validate("Period Code", PeriodCode);
                EmplJnlLine2.Validate("Document Date", DocumentDate);
                EmplJnlLine2.Validate("Document No.", DocumentNo);
                EmplJnlLine2.Validate("Starting Date", StartDate);
                EmplJnlLine2.Validate("Ending Date", EndDate);
                case AmountType of
                    AmountType::Amount,
                  AmountType::Percent:
                        EmplJnlLine2.Validate(Amount, Amount);
                    AmountType::Quantity:
                        EmplJnlLine2.Validate(Quantity, Amount);
                end;

                EmplJnlLine2."Source Code" := SourceCodeSetup."Employee Journal";
                if DescriptionText <> '' then
                    EmplJnlLine.Description := DescriptionText;
                EmplJnlLine2.Insert();
                LineNo := LineNo + 10000;
            end;

            trigger OnPreDataItem()
            begin
                if ElementCode = '' then
                    Error(Text000, EmplJnlLine.FieldCaption("Element Code"));

                if StartDate = 0D then
                    StartDate := CalcDate('<-CM>', Today);
                if EndDate = 0D then
                    EndDate := CalcDate('<CM>', Today);

                LineNo := 10000;
                EmplJnlLine.SetRange("Journal Template Name", EmplJnlLine."Journal Template Name");
                EmplJnlLine.SetRange("Journal Batch Name", EmplJnlLine."Journal Batch Name");
                if ClearLine then begin
                    if not EmplJnlLine.IsEmpty then
                        EmplJnlLine.DeleteAll
                end else
                    if EmplJnlLine.FindLast then
                        LineNo := EmplJnlLine."Line No." + 10000;

                Window.Open(Text001);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date of the entries that you want to include in the report or batch job.';

                        trigger OnValidate()
                        begin
                            PostingDateOnAfterValidate;
                        end;
                    }
                    field(PeriodCode; PeriodCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Code';
                        TableRelation = "Payroll Period";
                    }
                    field(DocumentDate; DocumentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the creation date of the related document.';
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field(ElementCode; ElementCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Element Code';
                        TableRelation = "Payroll Element";
                    }
                    field(AmountType; AmountType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amount Type';
                        OptionCaption = 'Amount,Percent,Quantity';
                    }
                    field(Amount; Amount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amount';
                        ToolTip = 'Specifies the amount.';
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(DescriptionText; DescriptionText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Description';
                        ToolTip = 'Specifies a description of the record or entry.';
                    }
                    field(ClearLine; ClearLine)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Clear Lines';
                        ToolTip = 'Specifies if the lines that are associated with the VAT ledger are deleted.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        SourceCodeSetup.Get();
    end;

    var
        EmplJnlLine: Record "Employee Journal Line";
        EmplJnlLine2: Record "Employee Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        PayrollPeriod: Record "Payroll Period";
        Window: Dialog;
        ElementType: Option Salary,Bonus,Deduction;
        ElementCode: Code[20];
        ClearLine: Boolean;
        Amount: Decimal;
        StartDate: Date;
        EndDate: Date;
        PostingDate: Date;
        DocumentDate: Date;
        DocumentNo: Code[20];
        LineNo: Integer;
        AmountType: Option Amount,Percent,Quantity;
        Text000: Label 'Please enter %1.';
        Text001: Label 'Employee No.   #1####################';
        PeriodCode: Code[10];
        DescriptionText: Text[50];

    [Scope('OnPrem')]
    procedure SetJnlLine(NewEmplJnlLine: Record "Employee Journal Line")
    begin
        EmplJnlLine := NewEmplJnlLine;
    end;

    [Scope('OnPrem')]
    procedure Initialize(NewElementType: Option; NewElementCode: Code[20]; NewAmountType: Option; NewAmount: Decimal; NewStartDate: Date; NewEndDate: Date)
    begin
        ElementType := NewElementType;
        ElementCode := NewElementCode;
        AmountType := NewAmountType;
        Amount := NewAmount;
        StartDate := NewStartDate;
        EndDate := NewEndDate;
    end;

    local procedure PostingDateOnAfterValidate()
    begin
        if PostingDate <> 0D then
            PeriodCode := PayrollPeriod.PeriodByDate(PostingDate);
    end;
}

