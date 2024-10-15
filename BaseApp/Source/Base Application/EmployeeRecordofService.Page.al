page 17359 "Employee Record of Service"
{
    Caption = 'Employee Record of Service';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = Employee;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                label(Control1210040)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Text19026267;
                    ShowCaption = false;
                    Style = Strong;
                    StyleExpr = TRUE;
                }
                field("Person.""Total Service (Days)"""; Person."Total Service (Days)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Service (Days)';
                    Editable = false;
                }
                field("Person.""Total Service (Months)"""; Person."Total Service (Months)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Service (Months)';
                    Editable = false;
                }
                field("Person.""Total Service (Years)"""; Person."Total Service (Years)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Service (Years)';
                    Editable = false;
                }
                field("Person.""Insured Service (Days)"""; Person."Insured Service (Days)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insured Service (Days)';
                    Editable = false;
                }
                field("Person.""Insured Service (Months)"""; Person."Insured Service (Months)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insured Service (Months)';
                    Editable = false;
                }
                field("Person.""Insured Service (Years)"""; Person."Insured Service (Years)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insured Service (Years)';
                    Editable = false;
                }
                field("Person.""Unbroken Service (Days)"""; Person."Unbroken Service (Days)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unbroken Service (Days)';
                    Editable = false;
                }
                field("Person.""Unbroken Service (Months)"""; Person."Unbroken Service (Months)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unbroken Service (Months)';
                    Editable = false;
                }
                field("Person.""Unbroken Service (Years)"""; Person."Unbroken Service (Years)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unbroken Service (Years)';
                    Editable = false;
                }
                field(CalculationDate; CalculationDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'As of Date';
                    ToolTip = 'Specifies a search method. If you select As of Date, and there is no currency exchange rate on a certain date, a message requesting that you enter a currency exchange rate for the date is displayed.';

                    trigger OnValidate()
                    begin
                        CalculationDateOnAfterValidate;
                    end;
                }
                field("TotalService[1]"; TotalService[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Service (Days)';
                    Editable = false;
                }
                field("TotalService[2]"; TotalService[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Service (Months)';
                    Editable = false;
                }
                field("TotalService[3]"; TotalService[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Service (Years)';
                    Editable = false;
                }
                field("InsuredService[1]"; InsuredService[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insured Service (Days)';
                    Editable = false;
                }
                field("InsuredService[2]"; InsuredService[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insured Service (Months)';
                    Editable = false;
                }
                field("InsuredService[3]"; InsuredService[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insured Service (Years)';
                    Editable = false;
                }
                field("UnbrokenService[1]"; UnbrokenService[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unbroken Service (Days)';
                    Editable = false;
                }
                field("UnbrokenService[2]"; UnbrokenService[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unbroken Service (Months)';
                    Editable = false;
                }
                field("UnbrokenService[3]"; UnbrokenService[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unbroken Service (Years)';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Clear(Person);
        if "Person No." <> '' then
            Person.Get("Person No.");

        Calculate;
    end;

    trigger OnOpenPage()
    begin
        CalculationDate := WorkDate;
    end;

    var
        Person: Record Person;
        RecordMgt: Codeunit "Record of Service Management";
        TotalService: array[3] of Integer;
        InsuredService: array[3] of Integer;
        UnbrokenService: array[3] of Integer;
        CalculationDate: Date;
        Text19026267: Label 'Initial Record of Service';

    [Scope('OnPrem')]
    procedure Calculate()
    begin
        RecordMgt.CalcEmplTotalService(Rec, CalculationDate, false, TotalService);
        RecordMgt.CalcEmplInsuredService(Rec, CalculationDate, InsuredService);
        RecordMgt.CalcEmplTotalService(Rec, CalculationDate, true, UnbrokenService);
    end;

    local procedure CalculationDateOnAfterValidate()
    begin
        Calculate;
    end;
}

