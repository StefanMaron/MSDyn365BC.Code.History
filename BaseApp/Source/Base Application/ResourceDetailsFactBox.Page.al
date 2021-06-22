page 9108 "Resource Details FactBox"
{
    Caption = 'Resource Details';
    PageType = CardPart;
    SourceTable = Resource;

    layout
    {
        area(content)
        {
            field("No."; "No.")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource No.';
                ToolTip = 'Specifies a number for the resource.';

                trigger OnDrillDown()
                begin
                    ShowDetails;
                end;
            }
            field(NoOfResourcePrices; NoOfResourcePrices)
            {
                ApplicationArea = Jobs;
                Caption = 'Prices';
                DrillDown = true;
                Editable = true;
                ToolTip = 'Specifies the resource prices.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                ObsoleteTag = '16.0';

                trigger OnDrillDown()
                var
                    RescPrice: Record "Resource Price";
                begin
                    RescPrice.SetRange(Type, RescPrice.Type::Resource);
                    RescPrice.SetRange(Code, "No.");

                    PAGE.Run(PAGE::"Resource Prices", RescPrice);
                end;
            }
            field(NoOfResourceCosts; NoOfResourceCosts)
            {
                ApplicationArea = Jobs;
                Caption = 'Costs';
                DrillDown = true;
                Editable = true;
                ToolTip = 'Specifies detailed information about costs for the resource.';

                trigger OnDrillDown()
                var
                    RescCost: Record "Resource Cost";
                begin
                    RescCost.SetRange(Type, RescCost.Type::Resource);
                    RescCost.SetRange(Code, "No.");

                    PAGE.Run(PAGE::"Resource Costs", RescCost);
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
        NoOfResourceCosts := 0;

        exit(Find(Which));
    end;

    trigger OnOpenPage()
    begin
        CalcNoOfRecords;
    end;

    var
        NoOfResourcePrices: Integer;
        NoOfResourceCosts: Integer;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Resource Card", Rec);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    local procedure CalcNoOfRecords()
    var
        ResourcePrice: Record "Resource Price";
        ResourceCost: Record "Resource Cost";
    begin
        ResourcePrice.Reset();
        ResourcePrice.SetRange(Type, ResourcePrice.Type::Resource);
        ResourcePrice.SetRange(Code, "No.");
        NoOfResourcePrices := ResourcePrice.Count();

        ResourceCost.Reset();
        ResourceCost.SetRange(Type, ResourceCost.Type::Resource);
        ResourceCost.SetRange(Code, "No.");
        NoOfResourceCosts := ResourceCost.Count();
    end;
}

