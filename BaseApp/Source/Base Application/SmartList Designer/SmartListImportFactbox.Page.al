#if not CLEAN19
page 9895 "SmartList Import FactBox"
{
    Caption = 'Import';
    Extensible = false;
    PageType = CardPart;
    SourceTable = "SmartList Import Results";
    UsageCategory = None;
    ObsoleteState = Pending;
    ObsoleteReason = 'The SmartList Designer is not supported in Business Central.';
    ObsoleteTag = '19.0';

    layout
    {
        area(Content)
        {
            cuegroup("Previous Results")
            {
                field(Successes; SuccessCount)
                {
                    ApplicationArea = All;
                    Caption = 'Successes';
                    Tooltip = 'Shows the number of successfully imported queries.';

                    trigger OnDrillDown()
                    var
                        Results: Record "SmartList Import Results";
                    begin
                        Results.SetRange(Success, true);
                        Page.Run(Page::"SmartList Import Results", Results);
                    end;
                }
                field(Failures; FailureCount)
                {
                    ApplicationArea = All;
                    Caption = 'Failures';
                    Tooltip = 'Shows the number of failed imported queries.';

                    trigger OnDrillDown()
                    var
                        Results: Record "SmartList Import Results";
                    begin
                        Results.SetRange(Success, false);
                        Page.Run(Page::"SmartList Import Results", Results);
                    end;
                }
            }
        }
    }

    procedure UpdateData(Results: Record "SmartList Import Results")
    begin
        Results.SetRange(Success, true, true);
        SuccessCount := Results.Count();
        Results.SetRange(Success, false, false);
        FailureCount := Results.Count();
        CurrPage.Update(false);
    end;

    var
        SuccessCount: Integer;
        FailureCount: Integer;
}
#endif