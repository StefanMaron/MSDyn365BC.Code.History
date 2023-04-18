page 5526 "Make Supply Orders"
{
    Caption = 'Make Supply Orders';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Manufacturing User Template";

    layout
    {
        area(content)
        {
            group("Order Planning")
            {
                Caption = 'Order Planning';
                field("Make Orders"; Rec."Make Orders")
                {
                    ApplicationArea = Planning;
                    Caption = 'Make Orders for';
                    ToolTip = 'Specifies the filters users select in the Make Supply Orders window that opens from the Order Planning window.';
                    ValuesAllowed = "The Active Line", "The Active Order", "All Lines";
                }
                group(Control4)
                {
                    InstructionalText = 'Multilevel production orders that are made with this function may generate new demand, which you can only see after you have recalculated a plan in the Order Planning window.';
                    ShowCaption = false;
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field("Create Purchase Order"; Rec."Create Purchase Order")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the filters users select in the Make Supply Orders window that opens from the Order Planning window.';

                    trigger OnValidate()
                    begin
                        PurchaseReqWkshTemplateEnable :=
                          "Create Purchase Order" = "Create Purchase Order"::"Copy to Req. Wksh";
                        PurchaseWkshNameEnable :=
                          "Create Purchase Order" = "Create Purchase Order"::"Copy to Req. Wksh";
                        CreatePurchaseOrderOnAfterVali();
                    end;
                }
                field("Purchase Req. Wksh. Template"; Rec."Purchase Req. Wksh. Template")
                {
                    ApplicationArea = Planning;
                    Enabled = PurchaseReqWkshTemplateEnable;
                    ToolTip = 'Specifies the template for the purchase requisition worksheet associated with this entry.';

                    trigger OnValidate()
                    begin
                        PurchaseReqWkshTemplateOnAfter();
                    end;
                }
                field("Purchase Wksh. Name"; Rec."Purchase Wksh. Name")
                {
                    ApplicationArea = Planning;
                    Enabled = PurchaseWkshNameEnable;
                    ToolTip = 'Specifies the purchase worksheet name associated with this entry.';

                    trigger OnValidate()
                    begin
                        PurchaseWkshNameOnAfterValidat();
                    end;
                }
                field("Create Production Order"; Rec."Create Production Order")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the filters users select in the Make Supply Orders window that opens from the Order Planning window.';

                    trigger OnValidate()
                    begin
                        ProdReqWkshTemplateEnable :=
                          "Create Production Order" = "Create Production Order"::"Copy to Req. Wksh";
                        ProdWkshNameEnable :=
                          "Create Production Order" = "Create Production Order"::"Copy to Req. Wksh";
                        CreateProductionOrderOnAfterVa();
                    end;
                }
                field("Prod. Req. Wksh. Template"; Rec."Prod. Req. Wksh. Template")
                {
                    ApplicationArea = Manufacturing;
                    Enabled = ProdReqWkshTemplateEnable;
                    ToolTip = 'Specifies the production requisition worksheet template associated with this entry.';

                    trigger OnValidate()
                    begin
                        ProdReqWkshTemplateOnAfterVali();
                    end;
                }
                field("Prod. Wksh. Name"; Rec."Prod. Wksh. Name")
                {
                    ApplicationArea = Manufacturing;
                    Enabled = ProdWkshNameEnable;
                    ToolTip = 'Specifies the production worksheet name associated with this entry.';

                    trigger OnValidate()
                    begin
                        ProdWkshNameOnAfterValidate();
                    end;
                }
                field("Create Transfer Order"; Rec."Create Transfer Order")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the filters users select in the Make Supply Orders window that opens from the Order Planning window.';

                    trigger OnValidate()
                    begin
                        TransferReqWkshTemplateEnable :=
                          "Create Transfer Order" = "Create Transfer Order"::"Copy to Req. Wksh";
                        TransferWkshNameEnable :=
                          "Create Transfer Order" = "Create Transfer Order"::"Copy to Req. Wksh";
                        CreateTransferOrderOnAfterVali();
                    end;
                }
                field("Transfer Req. Wksh. Template"; Rec."Transfer Req. Wksh. Template")
                {
                    ApplicationArea = Planning;
                    Enabled = TransferReqWkshTemplateEnable;
                    ToolTip = 'Specifies the transfer requisition worksheet template associated with this entry.';

                    trigger OnValidate()
                    begin
                        TransferReqWkshTemplateOnAfter();
                    end;
                }
                field("Transfer Wksh. Name"; Rec."Transfer Wksh. Name")
                {
                    ApplicationArea = Planning;
                    Enabled = TransferWkshNameEnable;
                    ToolTip = 'Specifies the transfer worksheet name associated with this entry.';

                    trigger OnValidate()
                    begin
                        TransferWkshNameOnAfterValidat();
                    end;
                }
                field("Create Assembly Order"; Rec."Create Assembly Order")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the filters users select in the Make Supply Orders window that opens from the Order Planning window.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        PurchaseReqWkshTemplateEnable :=
          "Create Purchase Order" = "Create Purchase Order"::"Copy to Req. Wksh";
        PurchaseWkshNameEnable :=
          "Create Purchase Order" = "Create Purchase Order"::"Copy to Req. Wksh";

        ProdReqWkshTemplateEnable :=
          "Create Production Order" = "Create Production Order"::"Copy to Req. Wksh";
        ProdWkshNameEnable :=
          "Create Production Order" = "Create Production Order"::"Copy to Req. Wksh";

        TransferReqWkshTemplateEnable :=
          "Create Transfer Order" = "Create Transfer Order"::"Copy to Req. Wksh";
        TransferWkshNameEnable :=
          "Create Transfer Order" = "Create Transfer Order"::"Copy to Req. Wksh";
    end;

    trigger OnInit()
    begin
        TransferWkshNameEnable := true;
        TransferReqWkshTemplateEnable := true;
        ProdWkshNameEnable := true;
        ProdReqWkshTemplateEnable := true;
        PurchaseWkshNameEnable := true;
        PurchaseReqWkshTemplateEnable := true;
    end;

    var
        [InDataSet]
        PurchaseReqWkshTemplateEnable: Boolean;
        [InDataSet]
        PurchaseWkshNameEnable: Boolean;
        [InDataSet]
        ProdReqWkshTemplateEnable: Boolean;
        [InDataSet]
        ProdWkshNameEnable: Boolean;
        [InDataSet]
        TransferReqWkshTemplateEnable: Boolean;
        [InDataSet]
        TransferWkshNameEnable: Boolean;

    local procedure CreatePurchaseOrderOnAfterVali()
    begin
        Modify(true);
    end;

    local procedure CreateProductionOrderOnAfterVa()
    begin
        Modify(true);
    end;

    local procedure CreateTransferOrderOnAfterVali()
    begin
        Modify(true);
    end;

    local procedure PurchaseReqWkshTemplateOnAfter()
    begin
        "Purchase Wksh. Name" := '';
        Modify(true);
    end;

    local procedure PurchaseWkshNameOnAfterValidat()
    begin
        Modify(true);
    end;

    local procedure ProdReqWkshTemplateOnAfterVali()
    begin
        "Prod. Wksh. Name" := '';
        Modify(true);
    end;

    local procedure ProdWkshNameOnAfterValidate()
    begin
        Modify(true);
    end;

    local procedure TransferReqWkshTemplateOnAfter()
    begin
        "Transfer Wksh. Name" := '';
        Modify(true);
    end;

    local procedure TransferWkshNameOnAfterValidat()
    begin
        Modify(true);
    end;
}

