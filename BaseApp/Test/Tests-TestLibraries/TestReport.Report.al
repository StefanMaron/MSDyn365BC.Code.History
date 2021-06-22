report 139300 TestReport
{
    DefaultLayout = RDLC;
    RDLCLayout = './TestReport.rdlc';

    dataset
    {
        dataitem(Date; Date)
        {
            column(PeriodStart_Date; Date."Period Start")
            {
            }

            trigger OnPreDataItem()
            begin
                Date.SetFilter("Period Start", Datefilter);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(Datefilter; Datefilter)
                {

                    trigger OnValidate()
                    begin
                        FilterTokens.MakeDateFilter(Datefilter);
                    end;
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
        FilterTokens: Codeunit "Filter Tokens";
        Datefilter: Text[1024];
}

