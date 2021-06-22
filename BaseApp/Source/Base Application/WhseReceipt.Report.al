report 7316 "Whse. - Receipt"
{
    DefaultLayout = RDLC;
    RDLCLayout = './WhseReceipt.rdlc';
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Receipt';
    UsageCategory = Documents;

    dataset
    {
        dataitem("Warehouse Receipt Header"; "Warehouse Receipt Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            column(No_WhseRcptHeader; "No.")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(CompanyName; COMPANYPROPERTY.DisplayName)
                {
                }
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(AssignedUserID_WhseRcptHeader; "Warehouse Receipt Header"."Assigned User ID")
                {
                    IncludeCaption = true;
                }
                column(LocationCode_WhseRcptHeader; "Warehouse Receipt Header"."Location Code")
                {
                    IncludeCaption = true;
                }
                column(No1_WhseRcptHeader; "Warehouse Receipt Header"."No.")
                {
                    IncludeCaption = true;
                }
                column(Show1; not Location."Bin Mandatory")
                {
                }
                column(Show2; Location."Bin Mandatory")
                {
                }
                column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
                {
                }
                column(WarehouseReceiptCaption; WarehouseReceiptCaptionLbl)
                {
                }
                dataitem("Warehouse Receipt Line"; "Warehouse Receipt Line")
                {
                    DataItemLink = "No." = FIELD("No.");
                    DataItemLinkReference = "Warehouse Receipt Header";
                    DataItemTableView = SORTING("No.", "Line No.");
                    column(ShelfNo_WhseRcptLine; "Shelf No.")
                    {
                        IncludeCaption = true;
                    }
                    column(ItemNo_WhseRcptLine; "Item No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Description_WhseRcptLine; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(UnitofMeasureCode_WhseRcptLine; "Unit of Measure Code")
                    {
                        IncludeCaption = true;
                    }
                    column(LocationCode_WhseRcptLine; "Location Code")
                    {
                        IncludeCaption = true;
                    }
                    column(Quantity_WhseRcptLine; Quantity)
                    {
                        IncludeCaption = true;
                    }
                    column(SourceNo_WhseRcptLine; "Source No.")
                    {
                        IncludeCaption = true;
                    }
                    column(SourceDocument_WhseRcptLine; "Source Document")
                    {
                        IncludeCaption = true;
                    }
                    column(ZoneCode_WhseRcptLine; "Zone Code")
                    {
                        IncludeCaption = true;
                    }
                    column(BinCode_WhseRcptLine; "Bin Code")
                    {
                        IncludeCaption = true;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        GetLocation("Location Code");
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                GetLocation("Location Code");
            end;
        }
    }

    requestpage
    {
        Caption = 'Warehouse Posted Receipt';

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Location: Record Location;
        CurrReportPageNoCaptionLbl: Label 'Page';
        WarehouseReceiptCaptionLbl: Label 'Warehouse - Receipt';

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.Init
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;
}

