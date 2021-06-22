page 956 "Actual/Sched. Summary FactBox"
{
    Caption = 'Actual/Scheduled Summary';
    PageType = CardPart;

    layout
    {
        area(content)
        {
            field(FirstDaySummary; DateQuantity[1])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[1];
                Editable = false;
            }
            field(SecondDaySummary; DateQuantity[2])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[2];
                Editable = false;
            }
            field(ThirdDaySummary; DateQuantity[3])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[3];
                Editable = false;
            }
            field(ForthDaySummary; DateQuantity[4])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[4];
                Editable = false;
            }
            field(FifthDaySummary; DateQuantity[5])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[5];
                Editable = false;
            }
            field(SixthDaySummary; DateQuantity[6])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[6];
                Editable = false;
            }
            field(SeventhDaySummary; DateQuantity[7])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[7];
                Editable = false;
            }
            field(TotalQtyText; TotalQtyText)
            {
                ApplicationArea = Jobs;
                Caption = 'Total';
                Editable = false;
                Style = Strong;
                StyleExpr = TRUE;
                ToolTip = 'Specifies the total.';
            }
            field(PresenceQty; PresenceQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Total Presence';
                ToolTip = 'Specifies the total presence (calculated in days or hours) for all resources on the line.';
            }
            field(AbsenceQty; AbsenceQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Total Absence';
                ToolTip = 'Specifies the total absence (calculated in days or hours) for all resources on the line.';
            }
        }
    }

    actions
    {
    }

    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
        DateDescription: array[7] of Text[30];
        DateQuantity: array[7] of Text[30];
        TotalQtyText: Text[30];
        TotalQuantity: Decimal;
        PresenceQty: Decimal;
        AbsenceQty: Decimal;

    procedure UpdateData(TimeSheetHeader: Record "Time Sheet Header")
    begin
        TimeSheetMgt.CalcActSchedFactBoxData(TimeSheetHeader, DateDescription, DateQuantity, TotalQtyText, TotalQuantity, AbsenceQty);
        PresenceQty := TotalQuantity - AbsenceQty;
        CurrPage.Update(false);
    end;
}

