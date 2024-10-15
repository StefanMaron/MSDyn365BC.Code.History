report 742 "VAT Report Request Page"
{
    Caption = 'VAT Report Request Page';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Report Header"; "VAT Report Header")
        {
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                field(Selection; Selection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include VAT entries';
                    ToolTip = 'Specifies whether to include VAT entries based on their status. For example, Open is useful when submitting for the first time, Open and Closed is useful when resubmitting.';
                }
                field(PeriodSelection; PeriodSelection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include VAT entries';
                    ToolTip = 'Specifies whether to include VAT entries only from the specified period, or also from previous periods within the specified year.';
                }
                field("""VAT Report Header"".""Start Date"""; "VAT Report Header"."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start Date';
                    Importance = Additional;
                    ToolTip = 'Specifies the first date of the reporting period.';
                }
                field("""VAT Report Header"".""End Date"""; "VAT Report Header"."End Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'End Date';
                    Importance = Additional;
                    ToolTip = 'Specifies the last date of the reporting period.';
                }
                field("Amounts in ACY"; "VAT Report Header"."Amounts in Add. Rep. Currency")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amounts in Add. Reporting Currency';
                    Importance = Additional;
                    ToolTip = 'Specifies if you want to report amounts in the additional reporting currency.';
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

    var
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
}

