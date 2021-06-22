page 5783 "Cross-Dock Opportunities"
{
    AutoSplitKey = true;
    Caption = 'Cross-Dock Opportunities';
    InsertAllowed = false;
    PageType = Worksheet;
    PopulateAllFields = true;
    SourceTable = "Whse. Cross-Dock Opportunity";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the item number of the items that can be cross-docked.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location on the warehouse receipt line related to this cross-dock opportunity.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of base units of measure in which the item has been received.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("To Source Document"; "To Source Document")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the type of source document for which the cross-dock opportunity can be used, such as sales order.';
                }
                field("To Source No."; "To Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document for which items can be cross-docked.';
                }
                field("Qty. Needed"; "Qty. Needed")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that is still needed on the document for which the items can be cross-docked.';
                    Visible = true;
                }
                field("Qty. Needed (Base)"; "Qty. Needed (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that is needed to complete the outbound source document line, in the base unit of measure.';
                    Visible = false;
                }
                field("Pick Qty."; "Pick Qty.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item that is on pick instructions for the outbound source document, but that has not yet been registered as picked.';
                    Visible = false;
                }
                field("Pick Qty. (Base)"; "Pick Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item that is on pick instructions for the outbound source document, but that has not yet been registered as picked.';
                    Visible = false;
                }
                field("Qty. to Cross-Dock"; "Qty. to Cross-Dock")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that is ready to cross-dock.';

                    trigger OnValidate()
                    begin
                        CalcValues;
                        QtytoCrossDockOnAfterValidate;
                    end;
                }
                field("Qty. to Cross-Dock (Base)"; "Qty. to Cross-Dock (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity, in the base units of measure, that is ready to cross-dock.';
                    Visible = false;
                }
                field("To-Src. Unit of Measure Code"; "To-Src. Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the unit of measure code on the source document line that needs the cross-dock opportunity item.';
                    Visible = true;
                }
                field("To-Src. Qty. per Unit of Meas."; "To-Src. Qty. per Unit of Meas.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity of base units of measure, on the source document line, that needs the cross-dock opportunity items.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the outbound warehouse activity should be started.';
                }
                field("Unit of Measure Code2"; "Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    Visible = false;
                }
                field("Qty. per Unit of Measure2"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of base units of measure in which the item has been received.';
                    Visible = false;
                }
                field("Reserved Quantity"; "Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the number of units of the item on the line reserved for the source document line.';
                }
                field("Reserved Qty. (Base)"; "Reserved Qty. (Base)")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the number of units of the item on the line reserved for the related source document line.';
                    Visible = false;
                }
                field("""Qty. Needed (Base)"" - ""Qty. to Cross-Dock (Base)"""; "Qty. Needed (Base)" - "Qty. to Cross-Dock (Base)")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Rem. Qty. to Cross-Dock (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the remaining base quantity that the program will suggest to put into the cross-dock bin on the put-away document line.';
                }
            }
            group(Control67)
            {
                ShowCaption = false;
                fixed(Control1903900601)
                {
                    ShowCaption = false;
                    group("Total Qty. To Handle (Base)")
                    {
                        Caption = 'Total Qty. To Handle (Base)';
                        field(QtyToHandleBase; QtyToHandleBase)
                        {
                            ApplicationArea = Warehouse;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(Text000; Text000)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Qty. on Cross-Dock Bin (Base)';
                            ToolTip = 'Specifies the quantity that the program will suggest to put into the cross-dock bin on the put-away document that is created when the receipt is posted.';
                            Visible = false;
                        }
                        field("Qty. to be Cross-Docked on Receipt Line"; Text000)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Qty. to be Cross-Docked on Receipt Line';
                            ToolTip = 'Specifies the sum of all the outbound lines requesting the item within the look-ahead period minus the quantity of the items that have already been placed in the cross-dock area.';
                            Visible = false;
                        }
                    }
                    group("Total Qty. To Be Cross-Docked")
                    {
                        Caption = 'Total Qty. To Be Cross-Docked';
                        field("Qty. Cross-Docked (Base)"; "Qty. Cross-Docked (Base)")
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Total Qty. To Be Cross-Docked';
                            DecimalPlaces = 0 : 5;
                            DrillDown = false;
                            Editable = false;
                            MultiLine = true;
                            ToolTip = 'Specifies the quantity, in the base units of measure, that have been cross-docked.';
                        }
                        field(QtyOnCrossDockBase; QtyOnCrossDockBase)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Qty. To Handle (Base)';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of items to be handled in this warehouse activity. The items to be handled are in the base unit of measure. The outstanding quantity in this field is suggested, but you can change the quantity if you want to. Each time you post a warehouse activity line, this field is updated with the new outstanding quantity.';
                        }
                        field(QtyToBeCrossDockedBase; QtyToBeCrossDockedBase)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Qty. To Handle (Base)';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of items to be handled in this warehouse activity. The items to be handled are in the base unit of measure. The outstanding quantity in this field is suggested, but you can change the quantity if you want to. Each time you post a warehouse activity line, this field is updated with the new outstanding quantity.';
                        }
                    }
                    group("Total Rem. Qty. to Cross-Dock (Base)")
                    {
                        Caption = 'Total Rem. Qty. to Cross-Dock (Base)';
                        field("""Total Qty. Needed (Base)"" - ""Qty. Cross-Docked (Base)"""; "Total Qty. Needed (Base)" - "Qty. Cross-Docked (Base)")
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Total Rem. Qty. to Cross-Dock (Base)';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            MultiLine = true;
                            ToolTip = 'Specifies the remaining quantity that the program will suggest to put into the cross-dock bin on the put-away document that is created when the receipt is posted.';
                        }
                        field(Placeholder2; Text000)
                        {
                            ApplicationArea = Warehouse;
                            Visible = false;
                        }
                        field(Placeholder3; Text000)
                        {
                            ApplicationArea = Warehouse;
                            Visible = false;
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Source &Document Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Source &Document Line';
                    Image = SourceDocLine;
                    ToolTip = 'View the line on a released source document that the warehouse activity is for. ';

                    trigger OnAction()
                    var
                        WMSMgt: Codeunit "WMS Management";
                    begin
                        WMSMgt.ShowSourceDocLine(
                          "To Source Type", "To Source Subtype", "To Source No.", "To Source Line No.", "To Source Subline No.");
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Refresh &Cross-Dock Opportunities")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Refresh &Cross-Dock Opportunities';
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Get the latest information about cross-dock opportunities.';

                    trigger OnAction()
                    var
                        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
                        Dummy: Decimal;
                    begin
                        if Confirm(Text001, false, WhseCrossDockOpportunity.TableCaption) then begin
                            CrossDockMgt.SetTemplate(TemplateName2, NameNo2, LocationCode2);
                            CrossDockMgt.CalculateCrossDockLine(
                              Rec, ItemNo2, VariantCode2,
                              QtyNeededSumBase, Dummy, QtyOnCrossDockBase,
                              LineNo2, QtyToHandleBase);
                        end;
                    end;
                }
                action("Autofill Qty. to Cross-Dock")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Autofill Qty. to Cross-Dock';
                    Image = AutofillQtyToHandle;
                    ToolTip = 'Have the system enter the outstanding quantity in the Qty. to Cross-Dock field.';

                    trigger OnAction()
                    begin
                        AutoFillQtyToCrossDock(Rec);
                        CurrPage.Update;
                    end;
                }
                action(Reserve)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve items for the selected line.';

                    trigger OnAction()
                    begin
                        ShowReservation;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcValues;
        CalcFields("Qty. Cross-Docked (Base)");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        "Item No." := ItemNo2;
        "Source Template Name" := TemplateName2;
        "Source Name/No." := NameNo2;
        "Source Line No." := LineNo2;
        "Variant Code" := VariantCode2;
        "Location Code" := LocationCode2;
    end;

    trigger OnOpenPage()
    begin
        CalcValues;
    end;

    var
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
        QtyToHandleBase: Decimal;
        QtyNeededSumBase: Decimal;
        QtyOnCrossDockBase: Decimal;
        Text001: Label 'The current %1 lines will be deleted, do you want to continue?';
        ItemNo2: Code[20];
        VariantCode2: Code[10];
        LocationCode2: Code[10];
        TemplateName2: Code[10];
        NameNo2: Code[20];
        LineNo2: Integer;
        QtyToBeCrossDockedBase: Decimal;
        UOMCode2: Code[10];
        QtyPerUOM2: Decimal;
        Text000: Label 'Placeholder';

    procedure SetValues(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; TemplateName: Code[10]; NameNo: Code[20]; LineNo: Integer; UOMCode: Code[10]; QtyPerUOM: Decimal)
    begin
        ItemNo2 := ItemNo;
        VariantCode2 := VariantCode;
        LocationCode2 := LocationCode;
        TemplateName2 := TemplateName;
        NameNo2 := NameNo;
        LineNo2 := LineNo;
        UOMCode2 := UOMCode;
        QtyPerUOM2 := QtyPerUOM;
    end;

    local procedure CalcValues()
    var
        ReceiptLine: Record "Warehouse Receipt Line";
        Dummy: Decimal;
    begin
        CrossDockMgt.CalcCrossDockedItems(ItemNo2, VariantCode2, '', LocationCode2, Dummy, QtyOnCrossDockBase);
        QtyOnCrossDockBase += CrossDockMgt.CalcCrossDockReceivedNotCrossDocked(LocationCode2, ItemNo2, VariantCode2);

        if TemplateName2 = '' then begin
            ReceiptLine.Get(NameNo2, LineNo2);
            QtyToHandleBase := ReceiptLine."Qty. to Receive (Base)";
        end;

        CalcFields("Qty. Cross-Docked (Base)", "Total Qty. Needed (Base)");
        QtyToBeCrossDockedBase := "Qty. Cross-Docked (Base)" - QtyOnCrossDockBase;
        if QtyToBeCrossDockedBase < 0 then
            QtyToBeCrossDockedBase := 0;

        "Item No." := ItemNo2;
        "Variant Code" := VariantCode2;
        "Location Code" := LocationCode2;
        "Unit of Measure Code" := UOMCode2;
        "Qty. per Unit of Measure" := QtyPerUOM2;
    end;

    procedure GetValues(var QtyToCrossDock: Decimal)
    begin
        QtyToCrossDock := QtyToBeCrossDockedBase;
    end;

    local procedure QtytoCrossDockOnAfterValidate()
    begin
        CurrPage.Update;
    end;
}

