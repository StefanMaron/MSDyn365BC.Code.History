page 9098 "Job No. of Prices FactBox"
{
    Caption = 'Job Details - No. of Prices';
    PageType = CardPart;
    SourceTable = Job;

    layout
    {
        area(content)
        {
            field("No."; "No.")
            {
                ApplicationArea = Jobs;
                Caption = 'Job No.';
                ToolTip = 'Specifies the job number.';

                trigger OnDrillDown()
                begin
                    ShowDetails;
                end;
            }
            field(NoOfResourcePrices; NoOfResourcePrices)
            {
                ApplicationArea = Jobs;
                Caption = 'Resource';
                ToolTip = 'Specifies prices for the resource.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                ObsoleteTag = '16.0';

                trigger OnDrillDown()
                var
                    JobResPrice: Record "Job Resource Price";
                begin
                    JobResPrice.SetRange("Job No.", "No.");

                    PAGE.Run(PAGE::"Job Resource Prices", JobResPrice);
                end;
            }
            field(NoOfItemPrices; NoOfItemPrices)
            {
                ApplicationArea = Jobs;
                Caption = 'Item';
                ToolTip = 'Specifies the total usage cost of items associated with this job.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                ObsoleteTag = '16.0';

                trigger OnDrillDown()
                var
                    JobItPrice: Record "Job Item Price";
                begin
                    JobItPrice.SetRange("Job No.", "No.");

                    PAGE.Run(PAGE::"Job Item Prices", JobItPrice);
                end;
            }
            field(NoOfAccountPrices; NoOfAccountPrices)
            {
                ApplicationArea = Jobs;
                Caption = 'G/L Account';
                ToolTip = 'Specifies the sum of values in the Job G/L Account Prices window.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                ObsoleteTag = '16.0';

                trigger OnDrillDown()
                var
                    JobAccPrice: Record "Job G/L Account Price";
                begin
                    JobAccPrice.SetRange("Job No.", "No.");

                    PAGE.Run(PAGE::"Job G/L Account Prices", JobAccPrice);
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcNoOfRecords;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        NoOfResourcePrices := 0;
        NoOfItemPrices := 0;
        NoOfAccountPrices := 0;

        exit(Find(Which));
    end;

    trigger OnOpenPage()
    begin
        CalcNoOfRecords;
    end;

    var
        NoOfResourcePrices: Integer;
        NoOfItemPrices: Integer;
        NoOfAccountPrices: Integer;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Job Card", Rec);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    local procedure CalcNoOfRecords()
    var
        JobResourcePrice: Record "Job Resource Price";
        JobItemPrice: Record "Job Item Price";
        JobAccountPrice: Record "Job G/L Account Price";
    begin
        JobResourcePrice.Reset();
        JobResourcePrice.SetRange("Job No.", "No.");
        NoOfResourcePrices := JobResourcePrice.Count();

        JobItemPrice.Reset();
        JobItemPrice.SetRange("Job No.", "No.");
        NoOfItemPrices := JobItemPrice.Count();

        JobAccountPrice.Reset();
        JobAccountPrice.SetRange("Job No.", "No.");
        NoOfAccountPrices := JobAccountPrice.Count();
    end;
}

