page 9892 "SmartList Export FactBox"
{
    Caption = 'Export';
    Extensible = false;
    PageType = CardPart;
    SourceTable = "SmartList Export Results";
    UsageCategory = None;

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
                    Tooltip = 'Shows the number of successfully exported queries.';

                    trigger OnDrillDown()
                    var
                        Results: Record "SmartList Export Results";
                    begin
                        Results.SetRange(Success, true);
                        Page.Run(Page::"SmartList Export Results", Results);
                    end;
                }
                field(Failures; FailureCount)
                {
                    ApplicationArea = All;
                    Caption = 'Failures';
                    Tooltip = 'Shows the number of failed exported queries.';

                    trigger OnDrillDown()
                    var
                        Results: Record "SmartList Export Results";
                    begin
                        Results.SetRange(Success, false);
                        Page.Run(Page::"SmartList Export Results", Results);
                    end;
                }
            }
        }
    }

    procedure UpdateData(Results: Record "SmartList Export Results")
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