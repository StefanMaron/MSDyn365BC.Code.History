page 6510 "Item Tracking Lines"
{
    Caption = 'Item Tracking Lines';
    DataCaptionFields = "Item No.", "Variant Code", Description;
    DelayedInsert = true;
    PageType = Worksheet;
    PopulateAllFields = true;
    PromotedActionCategories = 'New,Process,Report,Line';
    SourceTable = "Tracking Specification";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control59)
            {
                ShowCaption = false;
                fixed(Control1903651101)
                {
                    ShowCaption = false;
                    group(Source)
                    {
                        Caption = 'Source';
                        field(CurrentSourceCaption; CurrentSourceCaption)
                        {
                            ApplicationArea = ItemTracking;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("SourceQuantityArray[1]"; SourceQuantityArray[1])
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of the item that corresponds to the document line, which is indicated by 0 in the Undefined fields.';
                        }
                        field(Handle1; SourceQuantityArray[2])
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Qty. to Handle';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the item-tracked quantity to be handled. The quantities must correspond to those of the document line.';
                            Visible = Handle1Visible;
                        }
                        field(Invoice1; SourceQuantityArray[3])
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Qty. to Invoice';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the item-tracked quantity to be invoiced.';
                            Visible = Invoice1Visible;
                        }
                    }
                    group("Item Tracking")
                    {
                        Caption = 'Item Tracking';
                        field(Text020; Text020)
                        {
                            ApplicationArea = ItemTracking;
                            Visible = false;
                            ShowCaption = false;
                        }
                        field(Quantity_ItemTracking; TotalItemTrackingLine."Quantity (Base)")
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the item-tracked quantity of the item that corresponds to the document line, which is indicated by 0 in the Undefined fields.';
                        }
                        field(Handle2; TotalItemTrackingLine."Qty. to Handle (Base)")
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Qty. to Handle';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the item-tracked quantity to be handled. The quantities must correspond to those of the document line.';
                            Visible = Handle2Visible;
                        }
                        field(Invoice2; TotalItemTrackingLine."Qty. to Invoice (Base)")
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Qty. to Invoice';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the item-tracked quantity to be invoiced.';
                            Visible = Invoice2Visible;
                        }
                    }
                    group(Undefined)
                    {
                        Caption = 'Undefined';
                        field(Placeholder2; Text020)
                        {
                            ApplicationArea = ItemTracking;
                            Visible = false;
                            ShowCaption = false;
                        }
                        field(Quantity3; UndefinedQtyArray[1])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Caption = 'Undefined Quantity';
                            DecimalPlaces = 2 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the item-tracked quantity that remains to be assigned, according to the document quantity.';
                        }
                        field(Handle3; UndefinedQtyArray[2])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Caption = 'Undefined Quantity to Handle';
                            DecimalPlaces = 2 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the difference between the quantity that can be selected for the document line (which is shown in the Selectable field) and the quantity that you have selected in this window (shown in the Selected field). If you have specified more item tracking quantity than is required on the document line, this field shows the overflow quantity as a negative number in red.';
                            Visible = Handle3Visible;
                        }
                        field(Invoice3; UndefinedQtyArray[3])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Caption = 'Undefined Quantity to Invoice';
                            DecimalPlaces = 2 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the difference between the quantity that can be selected for the document line (which is shown in the Selectable field) and the quantity that you have selected in this window (shown in the Selected field). If you have specified more item tracking quantity than is required on the document line, this field shows the overflow quantity as a negative number in red.';
                            Visible = Invoice3Visible;
                        }
                    }
                }
            }
            group(Control82)
            {
                ShowCaption = false;
                field("ItemTrackingCode.Code"; ItemTrackingCode.Code)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item Tracking Code';
                    Editable = false;
                    Lookup = true;
                    ToolTip = 'Specifies the transferred item tracking lines.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        PAGE.RunModal(0, ItemTrackingCode);
                    end;
                }
                field("ItemTrackingCode.Description"; ItemTrackingCode.Description)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of what is being tracked.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(AvailabilitySerialNo; TrackingAvailable(Rec, 0))
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Availability, Serial No.';
                    Editable = false;
                    ToolTip = 'Specifies a warning icon if the sum of the quantities of the item in outbound documents is greater than the serial number quantity in inventory.';

                    trigger OnDrillDown()
                    begin
                        LookupAvailable(0);
                    end;
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = SerialNoEditable;
                    ToolTip = 'Specifies the serial number associated with the entry.';

                    trigger OnAssistEdit()
                    var
                        MaxQuantity: Decimal;
                    begin
                        OnBeforeSerialNoAssistEdit(Rec, xRec);

                        MaxQuantity := UndefinedQtyArray[1];

                        "Bin Code" := ForBinCode;
                        ItemTrackingDataCollection.AssistEditTrackingNo(Rec,
                          (CurrentSignFactor * SourceQuantityArray[1] < 0) and not
                          InsertIsBlocked, CurrentSignFactor, 0, MaxQuantity);
                        "Bin Code" := '';
                        CurrPage.Update;
                    end;

                    trigger OnValidate()
                    var
                        LotNo: Code[50];
                    begin
                        SerialNoOnAfterValidate;
                        if "Serial No." <> '' then begin
                            ItemTrackingDataCollection.FindLotNoBySNSilent(LotNo, Rec);
                            Validate("Lot No.", LotNo);
                            CurrPage.Update;
                        end;
                    end;
                }
                field("New Serial No."; "New Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = NewSerialNoEditable;
                    ToolTip = 'Specifies a new serial number that will take the place of the serial number in the Serial No. field.';
                    Visible = NewSerialNoVisible;
                }
                field(AvailabilityLotNo; TrackingAvailable(Rec, 1))
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Availability, Lot No.';
                    Editable = false;
                    ToolTip = 'Specifies a warning icon if the sum of the quantities of the item in outbound documents is greater than the lot number quantity in inventory.';

                    trigger OnDrillDown()
                    begin
                        LookupAvailable(1);
                    end;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = LotNoEditable;
                    ToolTip = 'Specifies the lot number of the item being handled for the associated document line.';

                    trigger OnAssistEdit()
                    var
                        MaxQuantity: Decimal;
                    begin
                        OnBeforeLotNoAssistEdit(Rec, xRec);

                        MaxQuantity := UndefinedQtyArray[1];

                        "Bin Code" := ForBinCode;
                        ItemTrackingDataCollection.AssistEditTrackingNo(Rec,
                          (CurrentSignFactor * SourceQuantityArray[1] < 0) and not
                          InsertIsBlocked, CurrentSignFactor, 1, MaxQuantity);
                        "Bin Code" := '';
                        CurrPage.Update;
                    end;

                    trigger OnValidate()
                    begin
                        LotNoOnAfterValidate;
                    end;
                }
                field("New Lot No."; "New Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = NewLotNoEditable;
                    ToolTip = 'Specifies a new lot number that will take the place of the lot number in the Lot No. field.';
                    Visible = NewLotNoVisible;
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Editable = ExpirationDateEditable;
                    ToolTip = 'Specifies the expiration date, if any, of the item carrying the item tracking number.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("New Expiration Date"; "New Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Editable = NewExpirationDateEditable;
                    ToolTip = 'Specifies a new expiration date.';
                    Visible = NewExpirationDateVisible;
                }
                field("Warranty Date"; "Warranty Date")
                {
                    ApplicationArea = ItemTracking;
                    Editable = WarrantyDateEditable;
                    ToolTip = 'Specifies that a warranty date must be entered manually.';
                    Visible = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = ItemNoEditable;
                    ToolTip = 'Specifies the number of the item associated with the entry.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = VariantCodeEditable;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = ItemTracking;
                    Editable = DescriptionEditable;
                    ToolTip = 'Specifies the description of the entry.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = ItemTracking;
                    Editable = LocationCodeEditable;
                    ToolTip = 'Specifies the location code for the entry.';
                    Visible = false;
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = ItemTracking;
                    Editable = QuantityBaseEditable;
                    ToolTip = 'Specifies the quantity on the line expressed in base units of measure.';

                    trigger OnValidate()
                    begin
                        QuantityBaseOnValidate;
                        QuantityBaseOnAfterValidate;
                    end;
                }
                field("Qty. to Handle (Base)"; "Qty. to Handle (Base)")
                {
                    ApplicationArea = ItemTracking;
                    Editable = QtyToHandleBaseEditable;
                    ToolTip = 'Specifies the quantity that you want to handle in the base unit of measure.';
                    Visible = QtyToHandleBaseVisible;

                    trigger OnValidate()
                    begin
                        QtytoHandleBaseOnAfterValidate;
                    end;
                }
                field("Qty. to Invoice (Base)"; "Qty. to Invoice (Base)")
                {
                    ApplicationArea = ItemTracking;
                    Editable = QtyToInvoiceBaseEditable;
                    ToolTip = 'Specifies how many of the items, in base units of measure, are scheduled for invoicing.';
                    Visible = QtyToInvoiceBaseVisible;

                    trigger OnValidate()
                    begin
                        QtytoInvoiceBaseOnAfterValidat;
                    end;
                }
                field("Quantity Handled (Base)"; "Quantity Handled (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity of serial/lot numbers shipped or received for the associated document line, expressed in base units of measure.';
                    Visible = false;
                }
                field("Quantity Invoiced (Base)"; "Quantity Invoiced (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity of serial/lot numbers that are invoiced with the associated document line, expressed in base units of measure.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
                    Visible = ApplToItemEntryVisible;
                }
                field("Appl.-from Item Entry"; "Appl.-from Item Entry")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied from.';
                    Visible = ApplFromItemEntryVisible;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(ButtonLineReclass)
            {
                Caption = '&Line';
                Image = Line;
                Visible = ButtonLineReclassVisible;
                action(Reclass_SerialNoInfoCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Serial No. Information Card';
                    Visible = ButtonLineReclassVisible;
                    Image = SNInfo;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Serial No. Information List";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Serial No." = FIELD("Serial No.");
                    ToolTip = 'View or edit detailed information about the serial number.';

                    trigger OnAction()
                    begin
                        TestField("Serial No.");
                    end;
                }
                action(Reclass_LotNoInfoCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot No. Information Card';
                    Visible = ButtonLineReclassVisible;
                    Image = LotInfo;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Lot No. Information List";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Lot No." = FIELD("Lot No.");
                    ToolTip = 'View or edit detailed information about the lot number.';

                    trigger OnAction()
                    begin
                        TestField("Lot No.");
                    end;
                }
                separator(Action69)
                {
                }
                action(NewSerialNoInformation)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'New S&erial No. Information';
                    Visible = ButtonLineReclassVisible;
                    Image = NewSerialNoProperties;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Create a record with detailed information about the serial number.';

                    trigger OnAction()
                    var
                        SerialNoInfoNew: Record "Serial No. Information";
                        SerialNoInfoForm: Page "Serial No. Information Card";
                    begin
                        TestField("New Serial No.");

                        Clear(SerialNoInfoForm);
                        SerialNoInfoForm.Init(Rec);

                        SerialNoInfoNew.SetRange("Item No.", "Item No.");
                        SerialNoInfoNew.SetRange("Variant Code", "Variant Code");
                        SerialNoInfoNew.SetRange("Serial No.", "New Serial No.");

                        SerialNoInfoForm.SetTableView(SerialNoInfoNew);
                        SerialNoInfoForm.Run;
                    end;
                }
                action(NewLotNoInformation)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'New L&ot No. Information';
                    Visible = ButtonLineReclassVisible;
                    Image = NewLotProperties;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunPageOnRec = false;
                    ToolTip = 'Create a record with detailed information about the lot number.';

                    trigger OnAction()
                    var
                        LotNoInfoNew: Record "Lot No. Information";
                        LotNoInfoForm: Page "Lot No. Information Card";
                    begin
                        TestField("New Lot No.");

                        Clear(LotNoInfoForm);
                        LotNoInfoForm.Init(Rec);

                        LotNoInfoNew.SetRange("Item No.", "Item No.");
                        LotNoInfoNew.SetRange("Variant Code", "Variant Code");
                        LotNoInfoNew.SetRange("Lot No.", "New Lot No.");

                        LotNoInfoForm.SetTableView(LotNoInfoNew);
                        LotNoInfoForm.Run;
                    end;
                }
            }
            group(ButtonLine)
            {
                Caption = '&Line';
                Image = Line;
                Visible = ButtonLineVisible;
                action(Line_SerialNoInfoCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Serial No. Information Card';
                    Visible = ButtonLineVisible;
                    Image = SNInfo;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Serial No. Information List";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Serial No." = FIELD("Serial No.");
                    ToolTip = 'View or edit detailed information about the serial number.';

                    trigger OnAction()
                    begin
                        TestField("Serial No.");
                    end;
                }
                action(Line_LotNoInfoCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot No. Information Card';
                    Visible = ButtonLineVisible;
                    Image = LotInfo;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Lot No. Information List";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Lot No." = FIELD("Lot No.");
                    ToolTip = 'View or edit detailed information about the lot number.';

                    trigger OnAction()
                    begin
                        TestField("Lot No.");
                    end;
                }
            }
        }
        area(processing)
        {
            group(FunctionsSupply)
            {
                Caption = 'F&unctions';
                Image = "Action";
                Visible = FunctionsSupplyVisible;
                action("Assign Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Assign &Serial No.';
                    Visible = FunctionsSupplyVisible;
                    Image = SerialNo;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Automatically assign the required serial numbers from predefined number series.';

                    trigger OnAction()
                    begin
                        if InsertIsBlocked then
                            exit;
                        AssignSerialNo;
                    end;
                }
                action("Assign Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Assign &Lot No.';
                    Visible = FunctionsSupplyVisible;
                    Image = Lot;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Automatically assign the required lot numbers from predefined number series.';

                    trigger OnAction()
                    begin
                        if InsertIsBlocked then
                            exit;
                        AssignLotNo;
                    end;
                }
                action("Create Customized SN")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Create Customized SN';
                    Visible = FunctionsSupplyVisible;
                    Image = CreateSerialNo;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Automatically assign the required serial numbers based on a number series that you define.';

                    trigger OnAction()
                    begin
                        if InsertIsBlocked then
                            exit;
                        CreateCustomizedSNByPage;
                    end;
                }
                action("Refresh Availability")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Refresh Availability';
                    Visible = FunctionsSupplyVisible;
                    Promoted = true;
                    PromotedCategory = Process;
                    Image = Refresh;
                    ToolTip = 'Update the availability information according to changes made by other users since you opened the window. ';

                    trigger OnAction()
                    begin
                        ItemTrackingDataCollection.RefreshTrackingAvailability(Rec, true);
                    end;
                }
            }
            group(FunctionsDemand)
            {
                Caption = 'F&unctions';
                Image = "Action";
                Visible = FunctionsDemandVisible;
                action("Assign &Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Assign &Serial No.';
                    Visible = FunctionsDemandVisible;
                    Image = SerialNo;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Automatically assign the required serial numbers from predefined number series.';

                    trigger OnAction()
                    begin
                        if InsertIsBlocked then
                            exit;
                        AssignSerialNo;
                    end;
                }
                action("Assign &Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Assign &Lot No.';
                    Visible = FunctionsDemandVisible;
                    Image = Lot;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Automatically assign the required lot numbers from predefined number series.';

                    trigger OnAction()
                    begin
                        if InsertIsBlocked then
                            exit;
                        AssignLotNo;
                    end;
                }
                action(CreateCustomizedSN)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Create Customized SN';
                    Visible = FunctionsDemandVisible;
                    Image = CreateSerialNo;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Automatically assign the required serial numbers based on a number series that you define.';

                    trigger OnAction()
                    begin
                        if InsertIsBlocked then
                            exit;
                        CreateCustomizedSNByPage;
                    end;
                }
                action("Select Entries")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Select &Entries';
                    Visible = FunctionsDemandVisible;
                    Image = SelectEntries;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Select from existing, available serial or lot numbers.';

                    trigger OnAction()
                    begin
                        if InsertIsBlocked then
                            exit;

                        SelectEntries;
                    end;
                }
                action(Action64)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Refresh Availability';
                    Visible = FunctionsDemandVisible;
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Update the availability information according to changes made by other users since you opened the window. ';

                    trigger OnAction()
                    begin
                        ItemTrackingDataCollection.RefreshTrackingAvailability(Rec, true);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateExpDateEditable;
    end;

    trigger OnAfterGetRecord()
    begin
        ExpirationDateOnFormat;
    end;

    trigger OnClosePage()
    var
        SkipWriteToDatabase: Boolean;
    begin
        SkipWriteToDatabase := false;
        OnBeforeClosePage(Rec, SkipWriteToDatabase);
        if UpdateUndefinedQty and not SkipWriteToDatabase then
            WriteToDatabase;
        if FormRunMode = FormRunMode::"Drop Shipment" then
            case CurrentSourceType of
                DATABASE::"Sales Line":
                    SynchronizeLinkedSources(StrSubstNo(Text015, Text016));
                DATABASE::"Purchase Line":
                    SynchronizeLinkedSources(StrSubstNo(Text015, Text017));
            end;

        if (FormRunMode = FormRunMode::Transfer) or IsOrderToOrderBindingToTransfer then
            SynchronizeLinkedSources('');
        SynchronizeWarehouseItemTracking;
    end;

    trigger OnDeleteRecord(): Boolean
    var
        TrackingSpec: Record "Tracking Specification";
        WMSManagement: Codeunit "WMS Management";
        AlreadyDeleted: Boolean;
    begin
        OnBeforeDeleteRecord(Rec);

        TrackingSpec."Item No." := "Item No.";
        TrackingSpec."Location Code" := "Location Code";
        TrackingSpec."Source Type" := "Source Type";
        TrackingSpec."Source Subtype" := "Source Subtype";
        WMSManagement.CheckItemTrackingChange(TrackingSpec, Rec);

        if not DeleteIsBlocked then begin
            AlreadyDeleted := TempItemTrackLineDelete.Get("Entry No.");
            TempItemTrackLineDelete.TransferFields(Rec);
            Delete(true);

            if not AlreadyDeleted then
                TempItemTrackLineDelete.Insert();
            ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
              TempItemTrackLineDelete, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 2);
            if TempItemTrackLineInsert.Get("Entry No.") then
                TempItemTrackLineInsert.Delete();
            if TempItemTrackLineModify.Get("Entry No.") then
                TempItemTrackLineModify.Delete();
        end;
        CalculateSums;

        exit(false);
    end;

    trigger OnInit()
    begin
        WarrantyDateEditable := true;
        ExpirationDateEditable := true;
        NewExpirationDateEditable := true;
        NewLotNoEditable := true;
        NewSerialNoEditable := true;
        DescriptionEditable := true;
        LotNoEditable := true;
        SerialNoEditable := true;
        QuantityBaseEditable := true;
        QtyToInvoiceBaseEditable := true;
        QtyToHandleBaseEditable := true;
        FunctionsDemandVisible := true;
        FunctionsSupplyVisible := true;
        ButtonLineVisible := true;
        QtyToInvoiceBaseVisible := true;
        Invoice3Visible := true;
        Invoice2Visible := true;
        Invoice1Visible := true;
        QtyToHandleBaseVisible := true;
        Handle3Visible := true;
        Handle2Visible := true;
        Handle1Visible := true;
        LocationCodeEditable := true;
        VariantCodeEditable := true;
        ItemNoEditable := true;
        InboundIsSet := false;
        ApplFromItemEntryVisible := false;
        ApplToItemEntryVisible := false;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if "Entry No." <> 0 then
            exit(false);
        "Entry No." := NextEntryNo;
        if (not InsertIsBlocked) and (not ZeroLineExists) then
            if not TestTempSpecificationExists then begin
                TempItemTrackLineInsert.TransferFields(Rec);
                OnInsertRecordOnBeforeTempItemTrackLineInsert(TempItemTrackLineInsert, Rec);
                TempItemTrackLineInsert.Insert();
                Insert;
                ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
                  TempItemTrackLineInsert, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 0);
            end;
        CalculateSums;

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        xTempTrackingSpec: Record "Tracking Specification" temporary;
    begin
        if InsertIsBlocked then
            if (xRec."Lot No." <> "Lot No.") or
               (xRec."Serial No." <> "Serial No.") or
               (xRec."Quantity (Base)" <> "Quantity (Base)")
            then
                exit(false);

        if not TestTempSpecificationExists then begin
            Modify;

            if (xRec."Lot No." <> "Lot No.") or (xRec."Serial No." <> "Serial No.") then begin
                xTempTrackingSpec := xRec;
                ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
                  xTempTrackingSpec, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 2);
            end;

            if TempItemTrackLineModify.Get("Entry No.") then
                TempItemTrackLineModify.Delete();
            if TempItemTrackLineInsert.Get("Entry No.") then begin
                TempItemTrackLineInsert.TransferFields(Rec);
                TempItemTrackLineInsert.Modify();
                ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
                  TempItemTrackLineInsert, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 1);
            end else begin
                TempItemTrackLineModify.TransferFields(Rec);
                TempItemTrackLineModify.Insert();
                ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
                  TempItemTrackLineModify, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 1);
            end;
        end;
        CalculateSums;

        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Qty. per Unit of Measure" := QtyPerUOM;
    end;

    trigger OnOpenPage()
    begin
        ItemNoEditable := false;
        VariantCodeEditable := false;
        LocationCodeEditable := false;
        if InboundIsSet then begin
            ApplFromItemEntryVisible := Inbound;
            ApplToItemEntryVisible := not Inbound;
        end;

        UpdateUndefinedQtyArray;

        CurrentPageIsOpen := true;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not UpdateUndefinedQty then
            exit(Confirm(Text006));

        if not ItemTrackingDataCollection.RefreshTrackingAvailability(Rec, false) then begin
            CurrPage.Update;
            exit(Confirm(Text019, true));
        end;
    end;

    var
        xTempItemTrackingLine: Record "Tracking Specification" temporary;
        TotalItemTrackingLine: Record "Tracking Specification";
        TempItemTrackLineInsert: Record "Tracking Specification" temporary;
        TempItemTrackLineModify: Record "Tracking Specification" temporary;
        TempItemTrackLineDelete: Record "Tracking Specification" temporary;
        TempItemTrackLineReserv: Record "Tracking Specification" temporary;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        TempReservEntry: Record "Reservation Entry" temporary;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        UndefinedQtyArray: array[3] of Decimal;
        SourceQuantityArray: array[5] of Decimal;
        QtyPerUOM: Decimal;
        QtyToAddAsBlank: Decimal;
        CurrentSignFactor: Integer;
        Text002: Label 'Quantity must be %1.';
        Text003: Label 'negative';
        Text004: Label 'positive';
        LastEntryNo: Integer;
        CurrentSourceType: Integer;
        SecondSourceID: Integer;
        IsAssembleToOrder: Boolean;
        ExpectedReceiptDate: Date;
        ShipmentDate: Date;
        Text005: Label 'Error when writing to database.';
        Text006: Label 'The corrections cannot be saved as excess quantity has been defined.\Close the form anyway?';
        Text007: Label 'Another user has modified the item tracking data since it was retrieved from the database.\Start again.';
        CurrentEntryStatus: Enum "Reservation Status";
        FormRunMode: Option ,Reclass,"Combined Ship/Rcpt","Drop Shipment",Transfer;
        InsertIsBlocked: Boolean;
        Text008: Label 'The quantity to create must be an integer.';
        Text009: Label 'The quantity to create must be positive.';
        Text011: Label 'Tracking specification with Serial No. %1 and Lot No. %2 already exists.';
        Text012: Label 'Tracking specification with Serial No. %1 already exists.';
        DeleteIsBlocked: Boolean;
        Text014: Label 'The total item tracking quantity %1 exceeds the %2 quantity %3.\The changes cannot be saved to the database.';
        Text015: Label 'Do you want to synchronize item tracking on the line with item tracking on the related drop shipment %1?';
        BlockCommit: Boolean;
        IsCorrection: Boolean;
        CurrentPageIsOpen: Boolean;
        CalledFromSynchWhseItemTrkg: Boolean;
        Inbound: Boolean;
        CurrentSourceCaption: Text[255];
        CurrentSourceRowID: Text[250];
        SecondSourceRowID: Text[250];
        Text016: Label 'purchase order line';
        Text017: Label 'sales order line';
        Text018: Label 'Saving item tracking line changes';
        ForBinCode: Code[20];
        Text019: Label 'There are availability warnings on one or more lines.\Close the form anyway?';
        Text020: Label 'Placeholder';
        [InDataSet]
        ApplFromItemEntryVisible: Boolean;
        [InDataSet]
        ApplToItemEntryVisible: Boolean;
        [InDataSet]
        ItemNoEditable: Boolean;
        [InDataSet]
        VariantCodeEditable: Boolean;
        [InDataSet]
        LocationCodeEditable: Boolean;
        [InDataSet]
        Handle1Visible: Boolean;
        [InDataSet]
        Handle2Visible: Boolean;
        [InDataSet]
        Handle3Visible: Boolean;
        [InDataSet]
        QtyToHandleBaseVisible: Boolean;
        [InDataSet]
        Invoice1Visible: Boolean;
        [InDataSet]
        Invoice2Visible: Boolean;
        [InDataSet]
        Invoice3Visible: Boolean;
        [InDataSet]
        QtyToInvoiceBaseVisible: Boolean;
        [InDataSet]
        NewSerialNoVisible: Boolean;
        [InDataSet]
        NewLotNoVisible: Boolean;
        [InDataSet]
        NewExpirationDateVisible: Boolean;
        [InDataSet]
        ButtonLineReclassVisible: Boolean;
        [InDataSet]
        ButtonLineVisible: Boolean;
        [InDataSet]
        FunctionsSupplyVisible: Boolean;
        [InDataSet]
        FunctionsDemandVisible: Boolean;
        InboundIsSet: Boolean;
        [InDataSet]
        QtyToHandleBaseEditable: Boolean;
        [InDataSet]
        QtyToInvoiceBaseEditable: Boolean;
        [InDataSet]
        QuantityBaseEditable: Boolean;
        [InDataSet]
        SerialNoEditable: Boolean;
        [InDataSet]
        LotNoEditable: Boolean;
        [InDataSet]
        DescriptionEditable: Boolean;
        [InDataSet]
        NewSerialNoEditable: Boolean;
        [InDataSet]
        NewLotNoEditable: Boolean;
        [InDataSet]
        NewExpirationDateEditable: Boolean;
        [InDataSet]
        ExpirationDateEditable: Boolean;
        [InDataSet]
        WarrantyDateEditable: Boolean;
        ExcludePostedEntries: Boolean;
        ProdOrderLineHandling: Boolean;
        UnincrementableStringErr: Label 'The value in the %1 field must have a number so that we can assign the next number in the series.', Comment = '%1 = serial number';

    procedure SetFormRunMode(Mode: Option ,Reclass,"Combined Ship/Rcpt","Drop Shipment",Transfer)
    begin
        FormRunMode := Mode;
    end;

    procedure GetFormRunMode(var Mode: Option ,Reclass,"Combined Ship/Rcpt","Drop Shipment",Transfer)
    begin
        Mode := FormRunMode;
    end;

    procedure SetSourceSpec(TrackingSpecification: Record "Tracking Specification"; AvailabilityDate: Date)
    var
        ReservEntry: Record "Reservation Entry";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecification2: Record "Tracking Specification" temporary;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        Controls: Option Handle,Invoice,Quantity,Reclass,Tracking;
    begin
        OnBeforeSetSourceSpec(TrackingSpecification, ReservEntry);

        GetItem(TrackingSpecification."Item No.");
        ForBinCode := TrackingSpecification."Bin Code";
        SetFilters(TrackingSpecification);
        TempTrackingSpecification.DeleteAll();
        TempItemTrackLineInsert.DeleteAll();
        TempItemTrackLineModify.DeleteAll();
        TempItemTrackLineDelete.DeleteAll();

        TempReservEntry.DeleteAll();
        LastEntryNo := 0;
        if ItemTrackingMgt.IsOrderNetworkEntity(TrackingSpecification."Source Type",
             TrackingSpecification."Source Subtype") and not (FormRunMode = FormRunMode::"Drop Shipment")
        then
            CurrentEntryStatus := CurrentEntryStatus::Surplus
        else
            CurrentEntryStatus := CurrentEntryStatus::Prospect;

        OnSetSourceSpecOnAfterAssignCurrentEntryStatus(TrackingSpecification, CurrentEntryStatus);

        // Set controls for Qty to handle:
        SetControls(Controls::Handle, GetHandleSource(TrackingSpecification));
        // Set controls for Qty to Invoice:
        SetControls(Controls::Invoice, GetInvoiceSource(TrackingSpecification));

        SetControls(Controls::Reclass, FormRunMode = FormRunMode::Reclass);

        if FormRunMode = FormRunMode::"Combined Ship/Rcpt" then
            SetControls(Controls::Tracking, false);
        if ItemTrackingMgt.ItemTrkgIsManagedByWhse(
             TrackingSpecification."Source Type",
             TrackingSpecification."Source Subtype",
             TrackingSpecification."Source ID",
             TrackingSpecification."Source Prod. Order Line",
             TrackingSpecification."Source Ref. No.",
             TrackingSpecification."Location Code",
             TrackingSpecification."Item No.")
        then begin
            SetControls(Controls::Quantity, false);
            QtyToHandleBaseEditable := true;
            DeleteIsBlocked := true;
        end;

        ReservEntry."Source Type" := TrackingSpecification."Source Type";
        ReservEntry."Source Subtype" := TrackingSpecification."Source Subtype";
        CurrentSignFactor := CreateReservEntry.SignFactor(ReservEntry);
        CurrentSourceCaption := ReservEntry.TextCaption;
        CurrentSourceType := ReservEntry."Source Type";

        if CurrentSignFactor < 0 then begin
            ExpectedReceiptDate := 0D;
            ShipmentDate := AvailabilityDate;
        end else begin
            ExpectedReceiptDate := AvailabilityDate;
            ShipmentDate := 0D;
        end;

        SourceQuantityArray[1] := TrackingSpecification."Quantity (Base)";
        SourceQuantityArray[2] := TrackingSpecification."Qty. to Handle (Base)";
        SourceQuantityArray[3] := TrackingSpecification."Qty. to Invoice (Base)";
        SourceQuantityArray[4] := TrackingSpecification."Quantity Handled (Base)";
        SourceQuantityArray[5] := TrackingSpecification."Quantity Invoiced (Base)";
        QtyPerUOM := TrackingSpecification."Qty. per Unit of Measure";

        ReservEntry.SetSourceFilter(
          TrackingSpecification."Source Type", TrackingSpecification."Source Subtype",
          TrackingSpecification."Source ID", TrackingSpecification."Source Ref. No.", true);
        ReservEntry.SetSourceFilter(
          TrackingSpecification."Source Batch Name", TrackingSpecification."Source Prod. Order Line");
        ReservEntry.SetRange("Untracked Surplus", false);
        // Transfer Receipt gets special treatment:
        if (TrackingSpecification."Source Type" = DATABASE::"Transfer Line") and
           (FormRunMode <> FormRunMode::Transfer) and
           (TrackingSpecification."Source Subtype" = 1)
        then begin
            ReservEntry.SetRange("Source Subtype", 0);
            AddReservEntriesToTempRecSet(ReservEntry, TempTrackingSpecification2, true, 8421504);
            ReservEntry.SetRange("Source Subtype", 1);
            ReservEntry.SetRange("Source Prod. Order Line", TrackingSpecification."Source Ref. No.");
            ReservEntry.SetRange("Source Ref. No.");
            DeleteIsBlocked := true;
            SetControls(Controls::Quantity, false);
        end;

        AddReservEntriesToTempRecSet(ReservEntry, TempTrackingSpecification, false, 0);

        TempReservEntry.CopyFilters(ReservEntry);

        TrackingSpecification.SetSourceFilter(
          TrackingSpecification."Source Type", TrackingSpecification."Source Subtype",
          TrackingSpecification."Source ID", TrackingSpecification."Source Ref. No.", true);
        TrackingSpecification.SetSourceFilter(
          TrackingSpecification."Source Batch Name", TrackingSpecification."Source Prod. Order Line");

        if TrackingSpecification.FindSet then
            repeat
                TempTrackingSpecification := TrackingSpecification;
                TempTrackingSpecification.Insert();
            until TrackingSpecification.Next = 0;

        // Data regarding posted quantities on transfers is collected from Item Ledger Entries:
        if TrackingSpecification."Source Type" = DATABASE::"Transfer Line" then
            CollectPostedTransferEntries(TrackingSpecification, TempTrackingSpecification);

        // Data regarding posted quantities on assembly orders is collected from Item Ledger Entries:
        if not ExcludePostedEntries then
            if (TrackingSpecification."Source Type" = DATABASE::"Assembly Line") or
               (TrackingSpecification."Source Type" = DATABASE::"Assembly Header")
            then
                CollectPostedAssemblyEntries(TrackingSpecification, TempTrackingSpecification);

        // Data regarding posted output quantities on prod.orders is collected from Item Ledger Entries:
        if TrackingSpecification."Source Type" = DATABASE::"Prod. Order Line" then
            if TrackingSpecification."Source Subtype" = 3 then
                CollectPostedOutputEntries(TrackingSpecification, TempTrackingSpecification);

        // If run for Drop Shipment a RowID is prepared for synchronisation:
        if FormRunMode = FormRunMode::"Drop Shipment" then
            CurrentSourceRowID := ItemTrackingMgt.ComposeRowID(TrackingSpecification."Source Type",
                TrackingSpecification."Source Subtype", TrackingSpecification."Source ID",
                TrackingSpecification."Source Batch Name", TrackingSpecification."Source Prod. Order Line",
                TrackingSpecification."Source Ref. No.");

        // Synchronization of outbound transfer order:
        if (TrackingSpecification."Source Type" = DATABASE::"Transfer Line") and
           (TrackingSpecification."Source Subtype" = 0)
        then begin
            BlockCommit := true;
            CurrentSourceRowID := ItemTrackingMgt.ComposeRowID(TrackingSpecification."Source Type",
                TrackingSpecification."Source Subtype", TrackingSpecification."Source ID",
                TrackingSpecification."Source Batch Name", TrackingSpecification."Source Prod. Order Line",
                TrackingSpecification."Source Ref. No.");
            SecondSourceRowID := ItemTrackingMgt.ComposeRowID(TrackingSpecification."Source Type",
                1, TrackingSpecification."Source ID",
                TrackingSpecification."Source Batch Name", TrackingSpecification."Source Prod. Order Line",
                TrackingSpecification."Source Ref. No.");
            FormRunMode := FormRunMode::Transfer;
        end;

        AddToGlobalRecordSet(TempTrackingSpecification);
        AddToGlobalRecordSet(TempTrackingSpecification2);
        CalculateSums;

        ItemTrackingDataCollection.SetCurrentBinAndItemTrkgCode(ForBinCode, ItemTrackingCode);
        ItemTrackingDataCollection.RetrieveLookupData(Rec, false);

        FunctionsDemandVisible := CurrentSignFactor * SourceQuantityArray[1] < 0;
        FunctionsSupplyVisible := not FunctionsDemandVisible;

        OnAfterSetSourceSpec(TrackingSpecification, Rec, AvailabilityDate, BlockCommit);
    end;

    procedure SetSecondSourceQuantity(SecondSourceQuantityArray: array[3] of Decimal)
    var
        Controls: Option Handle,Invoice;
    begin
        OnBeforeSetSecondSourceQuantity(SecondSourceQuantityArray);

        case SecondSourceQuantityArray[1] of
            DATABASE::"Warehouse Receipt Line", DATABASE::"Warehouse Shipment Line":
                begin
                    SourceQuantityArray[2] := SecondSourceQuantityArray[2]; // "Qty. to Handle (Base)"
                    SourceQuantityArray[3] := SecondSourceQuantityArray[3]; // "Qty. to Invoice (Base)"
                    SetControls(Controls::Invoice, false);
                end;
            else
                exit;
        end;

        CalculateSums;
    end;

    procedure SetSecondSourceRowID(RowID: Text[250])
    begin
        SecondSourceRowID := RowID;
    end;

    local procedure AddReservEntriesToTempRecSet(var ReservEntry: Record "Reservation Entry"; var TempTrackingSpecification: Record "Tracking Specification" temporary; SwapSign: Boolean; Color: Integer)
    var
        FromReservEntry: Record "Reservation Entry";
        AddTracking: Boolean;
    begin
        if ReservEntry.FindSet then
            repeat
                if Color = 0 then begin
                    TempReservEntry := ReservEntry;
                    TempReservEntry.Insert();
                end;
                if ReservEntry.TrackingExists then begin
                    AddTracking := true;
                    if SecondSourceID = DATABASE::"Warehouse Shipment Line" then
                        if FromReservEntry.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then
                            AddTracking := (FromReservEntry."Source Type" = DATABASE::"Assembly Header") = IsAssembleToOrder
                        else
                            AddTracking := not IsAssembleToOrder;

                    if AddTracking then begin
                        TempTrackingSpecification.TransferFields(ReservEntry);
                        // Ensure uniqueness of Entry No. by making it negative:
                        TempTrackingSpecification."Entry No." *= -1;
                        if SwapSign then
                            TempTrackingSpecification."Quantity (Base)" *= -1;
                        if Color <> 0 then begin
                            TempTrackingSpecification."Quantity Handled (Base)" :=
                              TempTrackingSpecification."Quantity (Base)";
                            TempTrackingSpecification."Quantity Invoiced (Base)" :=
                              TempTrackingSpecification."Quantity (Base)";
                            TempTrackingSpecification."Qty. to Handle (Base)" := 0;
                            TempTrackingSpecification."Qty. to Invoice (Base)" := 0;
                        end;
                        TempTrackingSpecification."Buffer Status" := Color;
                        OnAddReservEntriesToTempRecSetOnBeforeInsert(TempTrackingSpecification, ReservEntry, SwapSign, Color);
                        TempTrackingSpecification.Insert();
                    end;
                end;
            until ReservEntry.Next = 0;
    end;

    local procedure AddToGlobalRecordSet(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        ExpDate: Date;
        EntriesExist: Boolean;
    begin
        TempTrackingSpecification.SetCurrentKey("Lot No.", "Serial No.");
        if TempTrackingSpecification.Find('-') then
            repeat
                TempTrackingSpecification.SetTrackingFilterFromSpec(TempTrackingSpecification);
                TempTrackingSpecification.CalcSums("Quantity (Base)", "Qty. to Handle (Base)",
                  "Qty. to Invoice (Base)", "Quantity Handled (Base)", "Quantity Invoiced (Base)");
                if TempTrackingSpecification."Quantity (Base)" <> 0 then begin
                    Rec := TempTrackingSpecification;
                    "Quantity (Base)" *= CurrentSignFactor;
                    "Qty. to Handle (Base)" *= CurrentSignFactor;
                    "Qty. to Invoice (Base)" *= CurrentSignFactor;
                    "Quantity Handled (Base)" *= CurrentSignFactor;
                    "Quantity Invoiced (Base)" *= CurrentSignFactor;
                    "Qty. to Handle" :=
                      CalcQty("Qty. to Handle (Base)");
                    "Qty. to Invoice" :=
                      CalcQty("Qty. to Invoice (Base)");
                    "Entry No." := NextEntryNo;

                    // skip expiration date check for performance
                    // item tracking code is cached at the beginning of the caller method
                    if not ItemTrackingCode."Use Expiration Dates" then
                        "Buffer Status2" := "Buffer Status2"::"ExpDate blocked"
                    else begin
                        ExpDate := ItemTrackingMgt.ExistingExpirationDate(
                            "Item No.", "Variant Code",
                            "Lot No.", "Serial No.", false, EntriesExist);

                        if ExpDate <> 0D then begin
                            "Expiration Date" := ExpDate;
                            "Buffer Status2" := "Buffer Status2"::"ExpDate blocked";
                        end;
                    end;

                    OnBeforeAddToGlobalRecordSet(Rec, EntriesExist, CurrentSignFactor);
                    Insert;

                    if "Buffer Status" = 0 then begin
                        xTempItemTrackingLine := Rec;
                        xTempItemTrackingLine.Insert();
                    end;
                end;

                TempTrackingSpecification.Find('+');
                TempTrackingSpecification.ClearTrackingFilter;
            until TempTrackingSpecification.Next = 0;
    end;

    local procedure SetControls(Controls: Option Handle,Invoice,Quantity,Reclass,Tracking; SetAccess: Boolean)
    begin
        case Controls of
            Controls::Handle:
                begin
                    Handle1Visible := SetAccess;
                    Handle2Visible := SetAccess;
                    Handle3Visible := SetAccess;
                    QtyToHandleBaseVisible := SetAccess;
                    QtyToHandleBaseEditable := SetAccess;
                end;
            Controls::Invoice:
                begin
                    Invoice1Visible := SetAccess;
                    Invoice2Visible := SetAccess;
                    Invoice3Visible := SetAccess;
                    QtyToInvoiceBaseVisible := SetAccess;
                    QtyToInvoiceBaseEditable := SetAccess;
                end;
            Controls::Quantity:
                begin
                    QuantityBaseEditable := SetAccess;
                    SerialNoEditable := SetAccess;
                    LotNoEditable := SetAccess;
                    DescriptionEditable := SetAccess;
                    InsertIsBlocked := true;
                end;
            Controls::Reclass:
                begin
                    NewSerialNoVisible := SetAccess;
                    NewSerialNoEditable := SetAccess;
                    NewLotNoVisible := SetAccess;
                    NewLotNoEditable := SetAccess;
                    NewExpirationDateVisible := SetAccess;
                    NewExpirationDateEditable := ItemTrackingCode."Use Expiration Dates" and SetAccess;
                    ButtonLineReclassVisible := SetAccess;
                    ButtonLineVisible := not SetAccess;
                end;
            Controls::Tracking:
                begin
                    SerialNoEditable := SetAccess;
                    LotNoEditable := SetAccess;
                    ExpirationDateEditable := ItemTrackingCode."Use Expiration Dates" and SetAccess;
                    WarrantyDateEditable := SetAccess;
                    InsertIsBlocked := SetAccess;
                end;
        end;

        OnAfterSetControls(ItemTrackingCode, Controls, SetAccess);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if Item."No." <> ItemNo then begin
            Item.Get(ItemNo);
            Item.TestField("Item Tracking Code");
            if ItemTrackingCode.Code <> Item."Item Tracking Code" then
                ItemTrackingCode.Get(Item."Item Tracking Code");
        end;
    end;

    local procedure SetFilters(TrackingSpecification: Record "Tracking Specification")
    begin
        FilterGroup := 2;
        SetCurrentKey("Source ID", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.");
        SetRange("Source ID", TrackingSpecification."Source ID");
        SetRange("Source Type", TrackingSpecification."Source Type");
        SetRange("Source Subtype", TrackingSpecification."Source Subtype");
        SetRange("Source Batch Name", TrackingSpecification."Source Batch Name");
        if (TrackingSpecification."Source Type" = DATABASE::"Transfer Line") and
           (TrackingSpecification."Source Subtype" = 1)
        then begin
            SetFilter("Source Prod. Order Line", '0 | ' + Format(TrackingSpecification."Source Ref. No."));
            SetRange("Source Ref. No.");
        end else begin
            SetRange("Source Prod. Order Line", TrackingSpecification."Source Prod. Order Line");
            SetRange("Source Ref. No.", TrackingSpecification."Source Ref. No.");
        end;
        SetRange("Item No.", TrackingSpecification."Item No.");
        SetRange("Location Code", TrackingSpecification."Location Code");
        SetRange("Variant Code", TrackingSpecification."Variant Code");
        FilterGroup := 0;
    end;

    local procedure CheckLine(TrackingLine: Record "Tracking Specification")
    begin
        if TrackingLine."Quantity (Base)" * SourceQuantityArray[1] < 0 then
            if SourceQuantityArray[1] < 0 then
                Error(Text002, Text003)
            else
                Error(Text002, Text004);
    end;

    procedure CalculateSums()
    var
        xTrackingSpec: Record "Tracking Specification";
    begin
        xTrackingSpec.Copy(Rec);
        Reset;
        CalcSums("Quantity (Base)", "Qty. to Handle (Base)", "Qty. to Invoice (Base)");
        TotalItemTrackingLine := Rec;
        Copy(xTrackingSpec);

        UpdateUndefinedQtyArray;
    end;

    local procedure UpdateUndefinedQty(): Boolean
    var
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUndefinedQty(Rec, TotalItemTrackingLine, UndefinedQtyArray, SourceQuantityArray, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        UpdateUndefinedQtyArray;
        if ProdOrderLineHandling then // Avoid check for prod.journal lines
            exit(true);
        exit(Abs(SourceQuantityArray[1]) >= Abs(TotalItemTrackingLine."Quantity (Base)"));
    end;

    local procedure UpdateUndefinedQtyArray()
    begin
        UndefinedQtyArray[1] := SourceQuantityArray[1] - TotalItemTrackingLine."Quantity (Base)";
        UndefinedQtyArray[2] := SourceQuantityArray[2] - TotalItemTrackingLine."Qty. to Handle (Base)";
        UndefinedQtyArray[3] := SourceQuantityArray[3] - TotalItemTrackingLine."Qty. to Invoice (Base)";
    end;

    local procedure TempRecIsValid() OK: Boolean
    var
        ReservEntry: Record "Reservation Entry";
        RecordCount: Integer;
        IdenticalArray: array[2] of Boolean;
    begin
        OK := false;
        TempReservEntry.SetCurrentKey("Entry No.", Positive);
        ReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type",
          "Source Subtype", "Source Batch Name", "Source Prod. Order Line");

        ReservEntry.CopyFilters(TempReservEntry);

        if ReservEntry.FindSet then
            repeat
                if not TempReservEntry.Get(ReservEntry."Entry No.", ReservEntry.Positive) then
                    exit(false);
                if not EntriesAreIdentical(ReservEntry, TempReservEntry, IdenticalArray) then
                    exit(false);
                RecordCount += 1;
            until ReservEntry.Next = 0;

        OK := RecordCount = TempReservEntry.Count();
    end;

    local procedure EntriesAreIdentical(var ReservEntry1: Record "Reservation Entry"; var ReservEntry2: Record "Reservation Entry"; var IdenticalArray: array[2] of Boolean): Boolean
    begin
        IdenticalArray[1] := (
                              (ReservEntry1."Entry No." = ReservEntry2."Entry No.") and
                              (ReservEntry1."Item No." = ReservEntry2."Item No.") and
                              (ReservEntry1."Location Code" = ReservEntry2."Location Code") and
                              (ReservEntry1."Quantity (Base)" = ReservEntry2."Quantity (Base)") and
                              (ReservEntry1."Reservation Status" = ReservEntry2."Reservation Status") and
                              (ReservEntry1."Creation Date" = ReservEntry2."Creation Date") and
                              (ReservEntry1."Transferred from Entry No." = ReservEntry2."Transferred from Entry No.") and
                              (ReservEntry1."Source Type" = ReservEntry2."Source Type") and
                              (ReservEntry1."Source Subtype" = ReservEntry2."Source Subtype") and
                              (ReservEntry1."Source ID" = ReservEntry2."Source ID") and
                              (ReservEntry1."Source Batch Name" = ReservEntry2."Source Batch Name") and
                              (ReservEntry1."Source Prod. Order Line" = ReservEntry2."Source Prod. Order Line") and
                              (ReservEntry1."Source Ref. No." = ReservEntry2."Source Ref. No.") and
                              (ReservEntry1."Expected Receipt Date" = ReservEntry2."Expected Receipt Date") and
                              (ReservEntry1."Shipment Date" = ReservEntry2."Shipment Date") and
                              (ReservEntry1."Serial No." = ReservEntry2."Serial No.") and
                              (ReservEntry1."Created By" = ReservEntry2."Created By") and
                              (ReservEntry1."Changed By" = ReservEntry2."Changed By") and
                              (ReservEntry1.Positive = ReservEntry2.Positive) and
                              (ReservEntry1."Qty. per Unit of Measure" = ReservEntry2."Qty. per Unit of Measure") and
                              (ReservEntry1.Quantity = ReservEntry2.Quantity) and
                              (ReservEntry1."Action Message Adjustment" = ReservEntry2."Action Message Adjustment") and
                              (ReservEntry1.Binding = ReservEntry2.Binding) and
                              (ReservEntry1."Suppressed Action Msg." = ReservEntry2."Suppressed Action Msg.") and
                              (ReservEntry1."Planning Flexibility" = ReservEntry2."Planning Flexibility") and
                              (ReservEntry1."Lot No." = ReservEntry2."Lot No.") and
                              (ReservEntry1."Variant Code" = ReservEntry2."Variant Code") and
                              (ReservEntry1."Quantity Invoiced (Base)" = ReservEntry2."Quantity Invoiced (Base)"));

        IdenticalArray[2] := (
                              (ReservEntry1.Description = ReservEntry2.Description) and
                              (ReservEntry1."New Serial No." = ReservEntry2."New Serial No.") and
                              (ReservEntry1."New Lot No." = ReservEntry2."New Lot No.") and
                              (ReservEntry1."Expiration Date" = ReservEntry2."Expiration Date") and
                              (ReservEntry1."Warranty Date" = ReservEntry2."Warranty Date") and
                              (ReservEntry1."New Expiration Date" = ReservEntry2."New Expiration Date"));

        OnAfterEntriesAreIdentical(ReservEntry1, ReservEntry2, IdenticalArray);

        exit(IdenticalArray[1] and IdenticalArray[2]);
    end;

    local procedure QtyToHandleAndInvoiceChanged(var ReservEntry1: Record "Reservation Entry"; var ReservEntry2: Record "Reservation Entry"): Boolean
    begin
        exit(
          (ReservEntry1."Qty. to Handle (Base)" <> ReservEntry2."Qty. to Handle (Base)") or
          (ReservEntry1."Qty. to Invoice (Base)" <> ReservEntry2."Qty. to Invoice (Base)"));
    end;

    procedure NextEntryNo(): Integer
    begin
        LastEntryNo += 1;
        exit(LastEntryNo);
    end;

    local procedure WriteToDatabase()
    var
        Window: Dialog;
        ChangeType: Option Insert,Modify,Delete;
        EntryNo: Integer;
        NoOfLines: Integer;
        i: Integer;
        ModifyLoop: Integer;
        Decrease: Boolean;
    begin
        OnBeforeWriteToDatabase(Rec, CurrentPageIsOpen);
        if CurrentPageIsOpen then begin
            TempReservEntry.LockTable();
            TempRecValid;

            if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then
                QtyToAddAsBlank := 0
            else
                QtyToAddAsBlank := UndefinedQtyArray[1] * CurrentSignFactor;

            Reset;
            DeleteAll();

            Window.Open('#1############# @2@@@@@@@@@@@@@@@@@@@@@');
            Window.Update(1, Text018);
            NoOfLines := TempItemTrackLineInsert.Count + TempItemTrackLineModify.Count + TempItemTrackLineDelete.Count();
            if TempItemTrackLineDelete.Find('-') then begin
                repeat
                    i := i + 1;
                    if i mod 100 = 0 then
                        Window.Update(2, Round(i / NoOfLines * 10000, 1));
                    RegisterChange(TempItemTrackLineDelete, TempItemTrackLineDelete, ChangeType::Delete, false);
                    if TempItemTrackLineModify.Get(TempItemTrackLineDelete."Entry No.") then
                        TempItemTrackLineModify.Delete();
                until TempItemTrackLineDelete.Next = 0;
                TempItemTrackLineDelete.DeleteAll();
            end;

            for ModifyLoop := 1 to 2 do begin
                if TempItemTrackLineModify.Find('-') then
                    repeat
                        if xTempItemTrackingLine.Get(TempItemTrackLineModify."Entry No.") then begin
                            // Process decreases before increases
                            OnWriteToDatabaseOnBeforeRegisterDecrease(TempItemTrackLineModify);
                            Decrease := (xTempItemTrackingLine."Quantity (Base)" > TempItemTrackLineModify."Quantity (Base)");
                            if ((ModifyLoop = 1) and Decrease) or ((ModifyLoop = 2) and not Decrease) then begin
                                i := i + 1;
                                if (xTempItemTrackingLine."Serial No." <> TempItemTrackLineModify."Serial No.") or
                                   (xTempItemTrackingLine."Lot No." <> TempItemTrackLineModify."Lot No.") or
                                   (xTempItemTrackingLine."Appl.-from Item Entry" <> TempItemTrackLineModify."Appl.-from Item Entry") or
                                   (xTempItemTrackingLine."Appl.-to Item Entry" <> TempItemTrackLineModify."Appl.-to Item Entry")
                                then begin
                                    RegisterChange(xTempItemTrackingLine, xTempItemTrackingLine, ChangeType::Delete, false);
                                    RegisterChange(TempItemTrackLineModify, TempItemTrackLineModify, ChangeType::Insert, false);
                                    if (TempItemTrackLineInsert."Quantity (Base)" <> TempItemTrackLineInsert."Qty. to Handle (Base)") or
                                       (TempItemTrackLineInsert."Quantity (Base)" <> TempItemTrackLineInsert."Qty. to Invoice (Base)")
                                    then
                                        SetQtyToHandleAndInvoice(TempItemTrackLineInsert);
                                end else begin
                                    RegisterChange(xTempItemTrackingLine, TempItemTrackLineModify, ChangeType::Modify, false);
                                    SetQtyToHandleAndInvoice(TempItemTrackLineModify);
                                end;
                                TempItemTrackLineModify.Delete();
                            end;
                        end else begin
                            i := i + 1;
                            TempItemTrackLineModify.Delete();
                        end;
                        if i mod 100 = 0 then
                            Window.Update(2, Round(i / NoOfLines * 10000, 1));
                    until TempItemTrackLineModify.Next = 0;
            end;

            if TempItemTrackLineInsert.Find('-') then begin
                repeat
                    i := i + 1;
                    if i mod 100 = 0 then
                        Window.Update(2, Round(i / NoOfLines * 10000, 1));
                    if TempItemTrackLineModify.Get(TempItemTrackLineInsert."Entry No.") then
                        TempItemTrackLineInsert.TransferFields(TempItemTrackLineModify);
                    OnWriteToDatabaseOnBeforeRegisterInsert(TempItemTrackLineInsert);
                    if not RegisterChange(TempItemTrackLineInsert, TempItemTrackLineInsert, ChangeType::Insert, false) then
                        Error(Text005);
                    if (TempItemTrackLineInsert."Quantity (Base)" <> TempItemTrackLineInsert."Qty. to Handle (Base)") or
                       (TempItemTrackLineInsert."Quantity (Base)" <> TempItemTrackLineInsert."Qty. to Invoice (Base)")
                    then
                        SetQtyToHandleAndInvoice(TempItemTrackLineInsert);
                until TempItemTrackLineInsert.Next = 0;
                TempItemTrackLineInsert.DeleteAll();
            end;
            Window.Close;
        end else begin
            TempReservEntry.LockTable();
            TempRecValid;

            if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then
                QtyToAddAsBlank := 0
            else
                QtyToAddAsBlank := UndefinedQtyArray[1] * CurrentSignFactor;

            Reset;
            SetFilter("Buffer Status", '<>%1', 0);
            DeleteAll();
            Reset;

            xTempItemTrackingLine.Reset();
            SetCurrentKey("Entry No.");
            xTempItemTrackingLine.SetCurrentKey("Entry No.");
            if xTempItemTrackingLine.Find('-') then
                repeat
                    SetTrackingFilterFromSpec(xTempItemTrackingLine);
                    if Find('-') then begin
                        if RegisterChange(xTempItemTrackingLine, Rec, ChangeType::Modify, false) then begin
                            EntryNo := xTempItemTrackingLine."Entry No.";
                            xTempItemTrackingLine := Rec;
                            xTempItemTrackingLine."Entry No." := EntryNo;
                            xTempItemTrackingLine.Modify();
                        end;
                        SetQtyToHandleAndInvoice(Rec);
                        Delete;
                    end else begin
                        RegisterChange(xTempItemTrackingLine, xTempItemTrackingLine, ChangeType::Delete, false);
                        xTempItemTrackingLine.Delete();
                    end;
                until xTempItemTrackingLine.Next = 0;

            Reset;

            if Find('-') then
                repeat
                    if RegisterChange(Rec, Rec, ChangeType::Insert, false) then begin
                        xTempItemTrackingLine := Rec;
                        xTempItemTrackingLine.Insert();
                    end else
                        Error(Text005);
                    SetQtyToHandleAndInvoice(Rec);
                    Delete;
                until Next = 0;
        end;

        UpdateOrderTracking;
        ReestablishReservations; // Late Binding

        if not BlockCommit then
            Commit();
    end;

    local procedure RegisterChange(var OldTrackingSpecification: Record "Tracking Specification"; var NewTrackingSpecification: Record "Tracking Specification"; ChangeType: Option Insert,Modify,FullDelete,PartDelete,ModifyAll; ModifySharedFields: Boolean) OK: Boolean
    var
        ReservEntry1: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationMgt: Codeunit "Reservation Management";
        QtyToAdd: Decimal;
        LostReservQty: Decimal;
        IdenticalArray: array[2] of Boolean;
    begin
        OK := false;

        if ((CurrentSignFactor * NewTrackingSpecification."Qty. to Handle") < 0) and
           (FormRunMode <> FormRunMode::"Drop Shipment")
        then begin
            NewTrackingSpecification."Expiration Date" := 0D;
            OldTrackingSpecification."Expiration Date" := 0D;
        end;

        case ChangeType of
            ChangeType::Insert:
                begin
                    if (OldTrackingSpecification."Quantity (Base)" = 0) or not OldTrackingSpecification.TrackingExists then
                        exit(true);
                    TempReservEntry.SetTrackingFilterBlank;
                    OldTrackingSpecification."Quantity (Base)" :=
                      CurrentSignFactor *
                      ReservEngineMgt.AddItemTrackingToTempRecSet(
                        TempReservEntry, NewTrackingSpecification, CurrentSignFactor * OldTrackingSpecification."Quantity (Base)",
                        QtyToAddAsBlank, ItemTrackingCode);
                    TempReservEntry.ClearTrackingFilter;

                    // Late Binding
                    if ReservEngineMgt.RetrieveLostReservQty(LostReservQty) then begin
                        TempItemTrackLineReserv := NewTrackingSpecification;
                        TempItemTrackLineReserv."Quantity (Base)" := LostReservQty * CurrentSignFactor;
                        TempItemTrackLineReserv.Insert();
                    end;

                    if OldTrackingSpecification."Quantity (Base)" = 0 then
                        exit(true);

                    if FormRunMode = FormRunMode::Reclass then begin
                        CreateReservEntry.SetNewSerialLotNo(
                          OldTrackingSpecification."New Serial No.", OldTrackingSpecification."New Lot No.");
                        CreateReservEntry.SetNewExpirationDate(OldTrackingSpecification."New Expiration Date");
                    end;
                    CreateReservEntry.SetDates(
                      NewTrackingSpecification."Warranty Date", NewTrackingSpecification."Expiration Date");
                    CreateReservEntry.SetApplyFromEntryNo(NewTrackingSpecification."Appl.-from Item Entry");
                    CreateReservEntry.SetApplyToEntryNo(NewTrackingSpecification."Appl.-to Item Entry");
                    CreateReservEntry.CreateReservEntryFor(
                      OldTrackingSpecification."Source Type",
                      OldTrackingSpecification."Source Subtype",
                      OldTrackingSpecification."Source ID",
                      OldTrackingSpecification."Source Batch Name",
                      OldTrackingSpecification."Source Prod. Order Line",
                      OldTrackingSpecification."Source Ref. No.",
                      OldTrackingSpecification."Qty. per Unit of Measure",
                      0,
                      OldTrackingSpecification."Quantity (Base)",
                      OldTrackingSpecification."Serial No.",
                      OldTrackingSpecification."Lot No.");

                    OnAfterCreateReservEntryFor(OldTrackingSpecification, NewTrackingSpecification);

                    CreateReservEntry.CreateReservEntryExtraFields(OldTrackingSpecification, NewTrackingSpecification);

                    CreateReservEntry.CreateEntry(OldTrackingSpecification."Item No.",
                      OldTrackingSpecification."Variant Code",
                      OldTrackingSpecification."Location Code",
                      OldTrackingSpecification.Description,
                      ExpectedReceiptDate,
                      ShipmentDate, 0, CurrentEntryStatus);
                    CreateReservEntry.GetLastEntry(ReservEntry1);
                    OnRegisterChangeOnAfterCreateReservEntry(ReservEntry1, NewTrackingSpecification, OldTrackingSpecification);

                    if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then
                        ReservEngineMgt.UpdateActionMessages(ReservEntry1);

                    if ModifySharedFields then begin
                        ReservEntry1.SetPointerFilter;
                        ReservEntry1.SetTrackingFilterFromReservEntry(ReservEntry1);
                        ReservEntry1.SetFilter("Entry No.", '<>%1', ReservEntry1."Entry No.");
                        ModifyFieldsWithinFilter(ReservEntry1, NewTrackingSpecification);
                    end;

                    OK := true;
                end;
            ChangeType::Modify:
                begin
                    ReservEntry1.TransferFields(OldTrackingSpecification);
                    ReservEntry2.TransferFields(NewTrackingSpecification);

                    ReservEntry1."Entry No." := ReservEntry2."Entry No."; // If only entry no. has changed it should not trigger
                    if EntriesAreIdentical(ReservEntry1, ReservEntry2, IdenticalArray) then
                        exit(QtyToHandleAndInvoiceChanged(ReservEntry1, ReservEntry2));

                    if Abs(OldTrackingSpecification."Quantity (Base)") < Abs(NewTrackingSpecification."Quantity (Base)") then begin
                        // Item Tracking is added to any blank reservation entries:
                        TempReservEntry.SetTrackingFilterBlank;
                        QtyToAdd :=
                          CurrentSignFactor *
                          ReservEngineMgt.AddItemTrackingToTempRecSet(
                            TempReservEntry, NewTrackingSpecification,
                            CurrentSignFactor * (NewTrackingSpecification."Quantity (Base)" -
                                                 OldTrackingSpecification."Quantity (Base)"), QtyToAddAsBlank,
                            ItemTrackingCode);
                        TempReservEntry.ClearTrackingFilter;

                        // Late Binding
                        if ReservEngineMgt.RetrieveLostReservQty(LostReservQty) then begin
                            TempItemTrackLineReserv := NewTrackingSpecification;
                            TempItemTrackLineReserv."Quantity (Base)" := LostReservQty * CurrentSignFactor;
                            TempItemTrackLineReserv.Insert();
                        end;

                        OldTrackingSpecification."Quantity (Base)" := QtyToAdd;
                        OldTrackingSpecification."Warranty Date" := NewTrackingSpecification."Warranty Date";
                        OldTrackingSpecification."Expiration Date" := NewTrackingSpecification."Expiration Date";
                        OldTrackingSpecification.Description := NewTrackingSpecification.Description;
                        OnAfterCopyTrackingSpec(NewTrackingSpecification, OldTrackingSpecification);

                        RegisterChange(OldTrackingSpecification, OldTrackingSpecification,
                          ChangeType::Insert, not IdenticalArray[2]);
                    end else begin
                        TempReservEntry.SetTrackingFilterFromSpec(OldTrackingSpecification);
                        OldTrackingSpecification.ClearTracking;
                        OnAfterClearTrackingSpec(OldTrackingSpecification);
                        QtyToAdd :=
                          CurrentSignFactor *
                          ReservEngineMgt.AddItemTrackingToTempRecSet(
                            TempReservEntry, OldTrackingSpecification,
                            CurrentSignFactor * (OldTrackingSpecification."Quantity (Base)" -
                                                 NewTrackingSpecification."Quantity (Base)"), QtyToAddAsBlank,
                            ItemTrackingCode);
                        TempReservEntry.ClearTrackingFilter;
                        RegisterChange(NewTrackingSpecification, NewTrackingSpecification,
                          ChangeType::PartDelete, not IdenticalArray[2]);
                    end;
                    OnRegisterChangeOnAfterModify(NewTrackingSpecification, OldTrackingSpecification);
                    OK := true;
                end;
            ChangeType::FullDelete,
            ChangeType::PartDelete:
                begin
                    ReservationMgt.SetItemTrackingHandling(1); // Allow deletion of Item Tracking
                    ReservEntry1.TransferFields(OldTrackingSpecification);
                    ReservEntry1.SetPointerFilter;
                    ReservEntry1.SetTrackingFilterFromReservEntry(ReservEntry1);
                    if ChangeType = ChangeType::FullDelete then begin
                        TempReservEntry.SetTrackingFilterFromSpec(OldTrackingSpecification);
                        OldTrackingSpecification.ClearTracking;
                        OnAfterClearTrackingSpec(OldTrackingSpecification);
                        QtyToAdd :=
                          CurrentSignFactor *
                          ReservEngineMgt.AddItemTrackingToTempRecSet(
                            TempReservEntry, OldTrackingSpecification,
                            CurrentSignFactor * OldTrackingSpecification."Quantity (Base)",
                            QtyToAddAsBlank, ItemTrackingCode);
                        TempReservEntry.ClearTrackingFilter;
                        ReservationMgt.DeleteReservEntries(true, 0, ReservEntry1);
                        OnRegisterChangeOnAfterFullDelete(ReservEntry1);
                    end else begin
                        ReservationMgt.DeleteReservEntries(false, ReservEntry1."Quantity (Base)" -
                          OldTrackingSpecification."Quantity Handled (Base)", ReservEntry1);
                        if ModifySharedFields then begin
                            ReservEntry1.SetRange("Reservation Status");
                            ModifyFieldsWithinFilter(ReservEntry1, OldTrackingSpecification);
                        end;
                    end;
                    OK := true;
                end;
        end;
        SetQtyToHandleAndInvoice(NewTrackingSpecification);
    end;

    local procedure UpdateOrderTracking()
    var
        TempReservEntry: Record "Reservation Entry" temporary;
    begin
        if not ReservEngineMgt.CollectAffectedSurplusEntries(TempReservEntry) then
            exit;
        if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then
            exit;
        ReservEngineMgt.UpdateOrderTracking(TempReservEntry);
    end;

    local procedure ModifyFieldsWithinFilter(var ReservEntry1: Record "Reservation Entry"; var TrackingSpecification: Record "Tracking Specification")
    begin
        // Used to ensure that field values that are common to a SN/Lot are copied to all entries.
        if ReservEntry1.Find('-') then
            repeat
                ReservEntry1.Description := TrackingSpecification.Description;
                ReservEntry1."Warranty Date" := TrackingSpecification."Warranty Date";
                ReservEntry1."Expiration Date" := TrackingSpecification."Expiration Date";
                ReservEntry1."New Serial No." := TrackingSpecification."New Serial No.";
                ReservEntry1."New Lot No." := TrackingSpecification."New Lot No.";
                ReservEntry1."New Expiration Date" := TrackingSpecification."New Expiration Date";
                OnAfterMoveFields(TrackingSpecification, ReservEntry1);
                ReservEntry1.Modify();
            until ReservEntry1.Next = 0;
    end;

    local procedure SetQtyToHandleAndInvoice(TrackingSpecification: Record "Tracking Specification")
    var
        ReservEntry1: Record "Reservation Entry";
        TotalQtyToHandle: Decimal;
        TotalQtyToInvoice: Decimal;
        QtyToHandleThisLine: Decimal;
        QtyToInvoiceThisLine: Decimal;
    begin
        if IsCorrection then
            exit;

        TotalQtyToHandle := TrackingSpecification."Qty. to Handle (Base)" * CurrentSignFactor;
        TotalQtyToInvoice := TrackingSpecification."Qty. to Invoice (Base)" * CurrentSignFactor;

        ReservEntry1.TransferFields(TrackingSpecification);
        ReservEntry1.SetPointerFilter;
        ReservEntry1.SetTrackingFilterFromReservEntry(ReservEntry1);
        if TrackingSpecification.TrackingExists then begin
            ItemTrackingMgt.SetPointerFilter(TrackingSpecification);
            TrackingSpecification.SetTrackingFilterFromSpec(TrackingSpecification);
            if TrackingSpecification.Find('-') then
                repeat
                    if not TrackingSpecification.Correction then begin
                        QtyToInvoiceThisLine :=
                          TrackingSpecification."Quantity Handled (Base)" - TrackingSpecification."Quantity Invoiced (Base)";
                        if Abs(QtyToInvoiceThisLine) > Abs(TotalQtyToInvoice) then
                            QtyToInvoiceThisLine := TotalQtyToInvoice;
                        if TrackingSpecification."Qty. to Invoice (Base)" <> QtyToInvoiceThisLine then begin
                            TrackingSpecification."Qty. to Invoice (Base)" := QtyToInvoiceThisLine;
                            OnSetQtyToHandleAndInvoiceOnBeforeTrackingSpecModify(TrackingSpecification);
                            TrackingSpecification.Modify();
                        end;
                        TotalQtyToInvoice -= QtyToInvoiceThisLine;
                    end;
                until (TrackingSpecification.Next = 0);
        end;

        if TrackingSpecification."Lot No." <> '' then begin
            if (TrackingSpecification."Source Type" = DATABASE::"Transfer Line") and
               (TrackingSpecification."Source Subtype" = 1) and
               (TrackingSpecification."Source Prod. Order Line" <> 0) // Shipped
            then
                ReservEntry1.SetRange("Source Ref. No.");

            for ReservEntry1."Reservation Status" := ReservEntry1."Reservation Status"::Reservation to
                ReservEntry1."Reservation Status"::Prospect
            do begin
                ReservEntry1.SetRange("Reservation Status", ReservEntry1."Reservation Status");
                if ReservEntry1.Find('-') then
                    repeat
                        QtyToHandleThisLine := ReservEntry1."Quantity (Base)";
                        QtyToInvoiceThisLine := QtyToHandleThisLine;

                        if Abs(QtyToHandleThisLine) > Abs(TotalQtyToHandle) then
                            QtyToHandleThisLine := TotalQtyToHandle;
                        if Abs(QtyToInvoiceThisLine) > Abs(TotalQtyToInvoice) then
                            QtyToInvoiceThisLine := TotalQtyToInvoice;

                        if (ReservEntry1."Qty. to Handle (Base)" <> QtyToHandleThisLine) or
                           (ReservEntry1."Qty. to Invoice (Base)" <> QtyToInvoiceThisLine) and not ReservEntry1.Correction
                        then begin
                            ReservEntry1."Qty. to Handle (Base)" := QtyToHandleThisLine;
                            ReservEntry1."Qty. to Invoice (Base)" := QtyToInvoiceThisLine;
                            OnSetQtyToHandleAndInvoiceOnBeforeReservEntryModify(ReservEntry1, TrackingSpecification);
                            ReservEntry1.Modify();
                        end;
                        TotalQtyToHandle -= QtyToHandleThisLine;
                        TotalQtyToInvoice -= QtyToInvoiceThisLine;
                    until (ReservEntry1.Next = 0);
            end
        end else
            if ReservEntry1.Find('-') then
                if (ReservEntry1."Qty. to Handle (Base)" <> TotalQtyToHandle) or
                   (ReservEntry1."Qty. to Invoice (Base)" <> TotalQtyToInvoice) and not ReservEntry1.Correction
                then begin
                    ReservEntry1."Qty. to Handle (Base)" := TotalQtyToHandle;
                    ReservEntry1."Qty. to Invoice (Base)" := TotalQtyToInvoice;
                    OnSetQtyToHandleAndInvoiceOnBeforeReservEntryModify(ReservEntry1, TrackingSpecification);
                    ReservEntry1.Modify();
                end;
    end;

    local procedure CollectPostedTransferEntries(TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Used for collecting information about posted Transfer Shipments from the created Item Ledger Entries.
        if TrackingSpecification."Source Type" <> DATABASE::"Transfer Line" then
            exit;

        ItemEntryRelation.SetCurrentKey("Order No.", "Order Line No.");
        ItemEntryRelation.SetRange("Order No.", TrackingSpecification."Source ID");
        ItemEntryRelation.SetRange("Order Line No.", TrackingSpecification."Source Ref. No.");

        case TrackingSpecification."Source Subtype" of
            0: // Outbound
                ItemEntryRelation.SetRange("Source Type", DATABASE::"Transfer Shipment Line");
            1: // Inbound
                ItemEntryRelation.SetRange("Source Type", DATABASE::"Transfer Receipt Line");
        end;

        if ItemEntryRelation.Find('-') then
            repeat
                ItemLedgerEntry.Get(ItemEntryRelation."Item Entry No.");
                TempTrackingSpecification := TrackingSpecification;
                TempTrackingSpecification."Entry No." := ItemLedgerEntry."Entry No.";
                TempTrackingSpecification."Item No." := ItemLedgerEntry."Item No.";
                TempTrackingSpecification.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
                TempTrackingSpecification."Quantity (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Handled (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Invoiced (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
                TempTrackingSpecification.InitQtyToShip;
                OnBeforeCollectTempTrackingSpecificationInsert(TempTrackingSpecification, ItemLedgerEntry, TrackingSpecification);
                TempTrackingSpecification.Insert();
            until ItemEntryRelation.Next = 0;
    end;

    local procedure CollectPostedAssemblyEntries(TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Used for collecting information about posted Assembly Lines from the created Item Ledger Entries.
        if (TrackingSpecification."Source Type" <> DATABASE::"Assembly Line") and
           (TrackingSpecification."Source Type" <> DATABASE::"Assembly Header")
        then
            exit;

        ItemEntryRelation.SetCurrentKey("Order No.", "Order Line No.");
        ItemEntryRelation.SetRange("Order No.", TrackingSpecification."Source ID");
        ItemEntryRelation.SetRange("Order Line No.", TrackingSpecification."Source Ref. No.");
        if TrackingSpecification."Source Type" = DATABASE::"Assembly Line" then
            ItemEntryRelation.SetRange("Source Type", DATABASE::"Posted Assembly Line")
        else
            ItemEntryRelation.SetRange("Source Type", DATABASE::"Posted Assembly Header");

        if ItemEntryRelation.Find('-') then
            repeat
                ItemLedgerEntry.Get(ItemEntryRelation."Item Entry No.");
                TempTrackingSpecification := TrackingSpecification;
                TempTrackingSpecification."Entry No." := ItemLedgerEntry."Entry No.";
                TempTrackingSpecification."Item No." := ItemLedgerEntry."Item No.";
                TempTrackingSpecification.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
                TempTrackingSpecification."Quantity (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Handled (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Invoiced (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
                TempTrackingSpecification.InitQtyToShip;
                OnBeforeCollectTempTrackingSpecificationInsert(TempTrackingSpecification, ItemLedgerEntry, TrackingSpecification);
                TempTrackingSpecification.Insert();
            until ItemEntryRelation.Next = 0;
    end;

    local procedure CollectPostedOutputEntries(TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        BackwardFlushing: Boolean;
    begin
        // Used for collecting information about posted prod. order output from the created Item Ledger Entries.
        if TrackingSpecification."Source Type" <> DATABASE::"Prod. Order Line" then
            exit;

        if (TrackingSpecification."Source Type" = DATABASE::"Prod. Order Line") and
           (TrackingSpecification."Source Subtype" = 3)
        then begin
            ProdOrderRoutingLine.SetRange(Status, TrackingSpecification."Source Subtype");
            ProdOrderRoutingLine.SetRange("Prod. Order No.", TrackingSpecification."Source ID");
            ProdOrderRoutingLine.SetRange("Routing Reference No.", TrackingSpecification."Source Prod. Order Line");
            if ProdOrderRoutingLine.FindLast then
                BackwardFlushing :=
                  ProdOrderRoutingLine."Flushing Method" = ProdOrderRoutingLine."Flushing Method"::Backward;
        end;

        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", TrackingSpecification."Source ID");
        ItemLedgerEntry.SetRange("Order Line No.", TrackingSpecification."Source Prod. Order Line");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);

        if ItemLedgerEntry.Find('-') then
            repeat
                TempTrackingSpecification := TrackingSpecification;
                TempTrackingSpecification."Entry No." := ItemLedgerEntry."Entry No.";
                TempTrackingSpecification."Item No." := ItemLedgerEntry."Item No.";
                TempTrackingSpecification.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
                TempTrackingSpecification."Quantity (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Handled (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Invoiced (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
                TempTrackingSpecification.InitQtyToShip;
                OnBeforeCollectTempTrackingSpecificationInsert(TempTrackingSpecification, ItemLedgerEntry, TrackingSpecification);
                TempTrackingSpecification.Insert();

                if BackwardFlushing then begin
                    SourceQuantityArray[1] += ItemLedgerEntry.Quantity;
                    SourceQuantityArray[2] += ItemLedgerEntry.Quantity;
                    SourceQuantityArray[3] += ItemLedgerEntry.Quantity;
                end;

            until ItemLedgerEntry.Next = 0;
    end;

    procedure ZeroLineExists() OK: Boolean
    var
        xTrackingSpec: Record "Tracking Specification";
    begin
        if ("Quantity (Base)" <> 0) or TrackingExists then
            exit(false);
        xTrackingSpec.Copy(Rec);
        Reset;
        SetRange("Quantity (Base)", 0);
        SetTrackingFilterBlank;
        OK := not IsEmpty;
        Copy(xTrackingSpec);
    end;

    local procedure AssignSerialNo()
    var
        EnterQuantityToCreate: Page "Enter Quantity to Create";
        QtyToCreate: Decimal;
        QtyToCreateInt: Integer;
        CreateLotNo: Boolean;
    begin
        if ZeroLineExists then
            Delete;

        QtyToCreate := UndefinedQtyArray[1] * QtySignFactor;
        if QtyToCreate < 0 then
            QtyToCreate := 0;

        if QtyToCreate mod 1 <> 0 then
            Error(Text008);

        QtyToCreateInt := QtyToCreate;

        Clear(EnterQuantityToCreate);
        EnterQuantityToCreate.SetFields("Item No.", "Variant Code", QtyToCreate, false);
        if EnterQuantityToCreate.RunModal = ACTION::OK then begin
            EnterQuantityToCreate.GetFields(QtyToCreateInt, CreateLotNo);
            AssignSerialNoBatch(QtyToCreateInt, CreateLotNo);
        end;
    end;

    local procedure AssignSerialNoBatch(QtyToCreate: Integer; CreateLotNo: Boolean)
    var
        i: Integer;
    begin
        if QtyToCreate <= 0 then
            Error(Text009);
        if QtyToCreate mod 1 <> 0 then
            Error(Text008);

        GetItem("Item No.");

        if CreateLotNo then begin
            TestField("Lot No.", '');
            AssignNewLotNo;
            OnAfterAssignNewTrackingNo(Rec, xRec, FieldNo("Lot No."));
        end;

        Item.TestField("Serial Nos.");
        ItemTrackingDataCollection.SetSkipLot(true);
        for i := 1 to QtyToCreate do begin
            Validate("Quantity Handled (Base)", 0);
            Validate("Quantity Invoiced (Base)", 0);
            Validate("Serial No.", NoSeriesMgt.GetNextNo(Item."Serial Nos.", WorkDate, true));
            OnAfterAssignNewTrackingNo(Rec, xRec, FieldNo("Serial No."));
            Validate("Quantity (Base)", QtySignFactor);
            "Entry No." := NextEntryNo;
            if TestTempSpecificationExists then
                Error('');
            Insert;

            OnAssignSerialNoBatchOnAfterInsert(Rec);

            TempItemTrackLineInsert.TransferFields(Rec);
            TempItemTrackLineInsert.Insert();
            if i = QtyToCreate then
                ItemTrackingDataCollection.SetSkipLot(false);
            ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
              TempItemTrackLineInsert, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 0);
        end;
        CalculateSums;
    end;

    local procedure AssignLotNo()
    var
        QtyToCreate: Decimal;
    begin
        if ZeroLineExists then
            Delete;

        if (SourceQuantityArray[1] * UndefinedQtyArray[1] <= 0) or
           (Abs(SourceQuantityArray[1]) < Abs(UndefinedQtyArray[1]))
        then
            QtyToCreate := 0
        else
            QtyToCreate := UndefinedQtyArray[1];

        GetItem("Item No.");

        Validate("Quantity Handled (Base)", 0);
        Validate("Quantity Invoiced (Base)", 0);
        AssignNewLotNo;
        OnAfterAssignNewTrackingNo(Rec, xRec, FieldNo("Lot No."));
        "Qty. per Unit of Measure" := QtyPerUOM;
        Validate("Quantity (Base)", QtyToCreate);
        "Entry No." := NextEntryNo;
        TestTempSpecificationExists;
        Insert;

        OnAssignLotNoOnAfterInsert(Rec);

        TempItemTrackLineInsert.TransferFields(Rec);
        TempItemTrackLineInsert.Insert();
        ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
          TempItemTrackLineInsert, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 0);
        CalculateSums;
    end;

    local procedure AssignNewLotNo()
    var
        IsHandled: Boolean;
    begin
        OnBeforeAssignNewLotNo(Rec, IsHandled);
        if IsHandled then
            exit;

        Item.TestField("Lot Nos.");
        Validate("Lot No.", NoSeriesMgt.GetNextNo(Item."Lot Nos.", WorkDate, true));
    end;

    local procedure CreateCustomizedSNByPage()
    var
        EnterCustomizedSN: Page "Enter Customized SN";
        QtyToCreate: Decimal;
        QtyToCreateInt: Integer;
        Increment: Integer;
        CreateLotNo: Boolean;
        CustomizedSN: Code[50];
    begin
        if ZeroLineExists then
            Delete;

        QtyToCreate := UndefinedQtyArray[1] * QtySignFactor;
        if QtyToCreate < 0 then
            QtyToCreate := 0;

        if QtyToCreate mod 1 <> 0 then
            Error(Text008);

        QtyToCreateInt := QtyToCreate;

        Clear(EnterCustomizedSN);
        EnterCustomizedSN.SetFields("Item No.", "Variant Code", QtyToCreate, false);
        if EnterCustomizedSN.RunModal = ACTION::OK then begin
            EnterCustomizedSN.GetFields(QtyToCreateInt, CreateLotNo, CustomizedSN, Increment);
            CreateCustomizedSNBatch(QtyToCreateInt, CreateLotNo, CustomizedSN, Increment);
        end;
        CalculateSums;
    end;

    local procedure CreateCustomizedSNBatch(QtyToCreate: Decimal; CreateLotNo: Boolean; CustomizedSN: Code[50]; Increment: Integer)
    var
        i: Integer;
        Counter: Integer;
    begin
        if IncStr(CustomizedSN) = '' then
            Error(StrSubstNo(UnincrementableStringErr, CustomizedSN));
        NoSeriesMgt.TestManual(Item."Serial Nos.");

        if QtyToCreate <= 0 then
            Error(Text009);
        if QtyToCreate mod 1 <> 0 then
            Error(Text008);

        if CreateLotNo then begin
            TestField("Lot No.", '');
            AssignNewLotNo;
            OnAfterAssignNewTrackingNo(Rec, xRec, FieldNo("Lot No."));
        end;

        for i := 1 to QtyToCreate do begin
            Validate("Quantity Handled (Base)", 0);
            Validate("Quantity Invoiced (Base)", 0);
            Validate("Serial No.", CustomizedSN);
            OnAfterAssignNewTrackingNo(Rec, xRec, FieldNo("Serial No."));
            Validate("Quantity (Base)", QtySignFactor);
            "Entry No." := NextEntryNo;
            if TestTempSpecificationExists then
                Error('');
            Insert;
            TempItemTrackLineInsert.TransferFields(Rec);
            TempItemTrackLineInsert.Insert();
            ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
              TempItemTrackLineInsert, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 0);
            if i < QtyToCreate then begin
                Counter := Increment;
                repeat
                    CustomizedSN := IncStr(CustomizedSN);
                    Counter := Counter - 1;
                until Counter <= 0;
            end;
        end;
        CalculateSums;
    end;

    procedure TestTempSpecificationExists() Exists: Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        TrackingSpecification.Copy(Rec);
        SetCurrentKey("Lot No.", "Serial No.");
        SetRange("Serial No.", "Serial No.");
        if "Serial No." = '' then
            SetRange("Lot No.", "Lot No.");
        SetFilter("Entry No.", '<>%1', "Entry No.");
        SetRange("Buffer Status", 0);
        Exists := not IsEmpty;
        Copy(TrackingSpecification);
        if Exists and CurrentPageIsOpen then
            if "Serial No." = '' then
                Message(Text011, "Serial No.", "Lot No.")
            else
                Message(Text012, "Serial No.");
    end;

    local procedure QtySignFactor(): Integer
    begin
        if SourceQuantityArray[1] < 0 then
            exit(-1);

        exit(1)
    end;

    procedure RegisterItemTrackingLines(SourceSpecification: Record "Tracking Specification"; AvailabilityDate: Date; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        SourceSpecification.TestField("Source Type"); // Check if source has been set.
        if not CalledFromSynchWhseItemTrkg then
            TempTrackingSpecification.Reset();
        if not TempTrackingSpecification.Find('-') then
            exit;

        IsCorrection := SourceSpecification.Correction;
        ExcludePostedEntries := true;
        SetSourceSpec(SourceSpecification, AvailabilityDate);
        Reset;
        SetCurrentKey("Lot No.", "Serial No.");

        repeat
            SetTrackingFilterFromSpec(TempTrackingSpecification);
            if Find('-') then begin
                if IsCorrection then begin
                    "Quantity (Base)" += TempTrackingSpecification."Quantity (Base)";
                    "Qty. to Handle (Base)" += TempTrackingSpecification."Qty. to Handle (Base)";
                    "Qty. to Invoice (Base)" += TempTrackingSpecification."Qty. to Invoice (Base)";
                end else
                    Validate("Quantity (Base)", "Quantity (Base)" + TempTrackingSpecification."Quantity (Base)");
                Modify;
            end else begin
                TransferFields(SourceSpecification);
                CopyTrackingFromTrackingSpec(TempTrackingSpecification);
                "Warranty Date" := TempTrackingSpecification."Warranty Date";
                "Expiration Date" := TempTrackingSpecification."Expiration Date";
                if FormRunMode = FormRunMode::Reclass then begin
                    "New Serial No." := TempTrackingSpecification."New Serial No.";
                    "New Lot No." := TempTrackingSpecification."New Lot No.";
                    "New Expiration Date" := TempTrackingSpecification."New Expiration Date"
                end;
                OnAfterCopyTrackingSpec(TempTrackingSpecification, Rec);
                Validate("Quantity (Base)", TempTrackingSpecification."Quantity (Base)");
                "Entry No." := NextEntryNo;
                Insert;
            end;
        until TempTrackingSpecification.Next = 0;
        OnAfterRegisterItemTrackingLines(SourceSpecification, TempTrackingSpecification, Rec, AvailabilityDate);

        Reset;
        if Find('-') then
            repeat
                CheckLine(Rec);
            until Next = 0;

        SetTrackingFilterFromSpec(SourceSpecification);

        CalculateSums;
        if UpdateUndefinedQty then
            WriteToDatabase
        else
            Error(Text014, TotalItemTrackingLine."Quantity (Base)",
              LowerCase(TempReservEntry.TextCaption), SourceQuantityArray[1]);

        // Copy to inbound part of transfer
        if (FormRunMode = FormRunMode::Transfer) or IsOrderToOrderBindingToTransfer then
            SynchronizeLinkedSources('');
    end;

    procedure SynchronizeLinkedSources(DialogText: Text[250]): Boolean
    begin
        if CurrentSourceRowID = '' then
            exit(false);
        if SecondSourceRowID = '' then
            exit(false);

        ItemTrackingMgt.SynchronizeItemTracking(CurrentSourceRowID, SecondSourceRowID, DialogText);

        OnAfterSynchronizeLinkedSources(FormRunMode, CurrentSourceType, CurrentSourceRowID, SecondSourceRowID);
        exit(true);
    end;

    procedure SetBlockCommit(NewBlockCommit: Boolean)
    begin
        BlockCommit := NewBlockCommit;
    end;

    procedure SetCalledFromSynchWhseItemTrkg(CalledFromSynchWhseItemTrkg2: Boolean)
    begin
        CalledFromSynchWhseItemTrkg := CalledFromSynchWhseItemTrkg2;
        BlockCommit := true;
    end;

    local procedure UpdateExpDateColor()
    begin
        if ("Buffer Status2" = "Buffer Status2"::"ExpDate blocked") or (CurrentSignFactor < 0) then;
    end;

    local procedure UpdateExpDateEditable()
    begin
        ExpirationDateEditable := ItemTrackingCode."Use Expiration Dates" and
          not (("Buffer Status2" = "Buffer Status2"::"ExpDate blocked") or (CurrentSignFactor < 0));
    end;

    local procedure LookupAvailable(LookupMode: Enum "Item Tracking Type")
    begin
        "Bin Code" := ForBinCode;
        ItemTrackingDataCollection.LookupTrackingAvailability(Rec, LookupMode);
        "Bin Code" := '';
        CurrPage.Update;
    end;

    local procedure TrackingAvailable(var TrackingSpecification: Record "Tracking Specification"; LookupMode: Enum "Item Tracking Type"): Boolean
    begin
        exit(ItemTrackingDataCollection.TrackingAvailable(TrackingSpecification, LookupMode));
    end;

    local procedure SelectEntries()
    var
        xTrackingSpec: Record "Tracking Specification";
        MaxQuantity: Decimal;
    begin
        xTrackingSpec.CopyFilters(Rec);
        MaxQuantity := UndefinedQtyArray[1];
        if MaxQuantity * CurrentSignFactor > 0 then
            MaxQuantity := 0;
        "Bin Code" := ForBinCode;
        ItemTrackingDataCollection.SelectMultipleTrackingNo(Rec, MaxQuantity, CurrentSignFactor);
        "Bin Code" := '';
        if FindSet then
            repeat
                case "Buffer Status" of
                    "Buffer Status"::MODIFY:
                        begin
                            if TempItemTrackLineModify.Get("Entry No.") then
                                TempItemTrackLineModify.Delete();
                            if TempItemTrackLineInsert.Get("Entry No.") then begin
                                TempItemTrackLineInsert.TransferFields(Rec);
                                OnSelectEntriesOnAfterTransferFields(TempItemTrackLineInsert, Rec);
                                TempItemTrackLineInsert.Modify();
                            end else begin
                                TempItemTrackLineModify.TransferFields(Rec);
                                OnSelectEntriesOnAfterTransferFields(TempItemTrackLineModify, Rec);
                                TempItemTrackLineModify.Insert();
                            end;
                        end;
                    "Buffer Status"::INSERT:
                        begin
                            TempItemTrackLineInsert.TransferFields(Rec);
                            OnSelectEntriesOnAfterTransferFields(TempItemTrackLineInsert, Rec);
                            TempItemTrackLineInsert.Insert();
                        end;
                end;
                "Buffer Status" := 0;
                Modify;
            until Next = 0;
        LastEntryNo := "Entry No.";
        CalculateSums;
        UpdateUndefinedQtyArray;
        CopyFilters(xTrackingSpec);
        CurrPage.Update(false);
    end;

    local procedure ReestablishReservations()
    var
        LateBindingMgt: Codeunit "Late Binding Management";
    begin
        if TempItemTrackLineReserv.FindSet then
            repeat
                LateBindingMgt.ReserveItemTrackingLine(TempItemTrackLineReserv, 0, TempItemTrackLineReserv."Quantity (Base)");
                SetQtyToHandleAndInvoice(TempItemTrackLineReserv);
            until TempItemTrackLineReserv.Next = 0;
        TempItemTrackLineReserv.DeleteAll();
    end;

    procedure SetInbound(NewInbound: Boolean)
    begin
        InboundIsSet := true;
        Inbound := NewInbound;
    end;

    local procedure SerialNoOnAfterValidate()
    begin
        OnBeforeSerialNoOnAfterValidate(Rec);

        UpdateExpDateEditable;
        CurrPage.Update;
    end;

    local procedure LotNoOnAfterValidate()
    begin
        UpdateExpDateEditable;
        CurrPage.Update;
    end;

    local procedure QuantityBaseOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure QuantityBaseOnValidate()
    begin
        CheckLine(Rec);
    end;

    local procedure QtytoHandleBaseOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure QtytoInvoiceBaseOnAfterValidat()
    begin
        CurrPage.Update;
    end;

    local procedure ExpirationDateOnFormat()
    begin
        UpdateExpDateColor;
    end;

    local procedure TempRecValid()
    begin
        if not TempRecIsValid then
            Error(Text007);
    end;

    procedure GetEditableSettings(var ItemNoEditable2: Boolean; var VariantCodeEditable2: Boolean; var LocationCodeEditable2: Boolean; var QtyToHandleBaseEditable2: Boolean; var QtyToInvoiceBaseEditable2: Boolean; var QuantityBaseEditable2: Boolean; var SerialNoEditable2: Boolean; var LotNoEditable2: Boolean; var DescriptionEditable2: Boolean; var NewSerialNoEditable2: Boolean; var NewLotNoEditable2: Boolean; var NewExpirationDateEditable2: Boolean; var ExpirationDateEditable2: Boolean; var WarrantyDateEditable2: Boolean)
    begin
        ItemNoEditable2 := ItemNoEditable;
        VariantCodeEditable2 := VariantCodeEditable;
        LocationCodeEditable2 := LocationCodeEditable;
        QtyToHandleBaseEditable2 := QtyToHandleBaseEditable;
        QtyToInvoiceBaseEditable2 := QtyToInvoiceBaseEditable;
        QuantityBaseEditable2 := QuantityBaseEditable;
        SerialNoEditable2 := SerialNoEditable;
        LotNoEditable2 := LotNoEditable;
        DescriptionEditable2 := DescriptionEditable;
        NewSerialNoEditable2 := NewSerialNoEditable;
        NewLotNoEditable2 := NewLotNoEditable;
        NewExpirationDateEditable2 := NewExpirationDateEditable;
        ExpirationDateEditable2 := ExpirationDateEditable;
        WarrantyDateEditable2 := WarrantyDateEditable;
    end;

    procedure GetVisibleSettings(var Handle1Visible2: Boolean; var Handle2Visible2: Boolean; var Handle3Visible2: Boolean; var QtyToHandleBaseVisible2: Boolean; var Invoice1Visible2: Boolean; var Invoice2Visible2: Boolean; var Invoice3Visible2: Boolean; var QtyToInvoiceBaseVisible2: Boolean; var NewSerialNoVisible2: Boolean; var NewLotNoVisible2: Boolean; var NewExpirationDateVisible2: Boolean; var ButtonLineReclassVisible2: Boolean; var ButtonLineVisible2: Boolean; var FunctionsSupplyVisible2: Boolean; var FunctionsDemandVisible2: Boolean; var Inbound2: Boolean; var InboundIsSet2: Boolean)
    begin
        Handle1Visible2 := Handle1Visible;
        Handle2Visible2 := Handle2Visible;
        Handle3Visible2 := Handle3Visible;
        QtyToHandleBaseVisible2 := QtyToHandleBaseVisible;
        Invoice1Visible2 := Invoice1Visible;
        Invoice2Visible2 := Invoice2Visible;
        Invoice3Visible2 := Invoice3Visible;
        QtyToInvoiceBaseVisible2 := QtyToInvoiceBaseVisible;
        NewSerialNoVisible2 := NewSerialNoVisible;
        NewLotNoVisible2 := NewLotNoVisible;
        NewExpirationDateVisible2 := NewExpirationDateVisible;
        ButtonLineReclassVisible2 := ButtonLineReclassVisible;
        ButtonLineVisible2 := ButtonLineVisible;
        FunctionsSupplyVisible2 := FunctionsSupplyVisible;
        FunctionsDemandVisible2 := FunctionsDemandVisible;
        Inbound2 := Inbound;
        InboundIsSet2 := InboundIsSet;
    end;

    procedure GetVariables(var TempTrackingSpecInsert2: Record "Tracking Specification" temporary; var TempTrackingSpecModify2: Record "Tracking Specification" temporary; var TempTrackingSpecDelete2: Record "Tracking Specification" temporary; var Item2: Record Item; var UndefinedQtyArray2: array[3] of Decimal; var SourceQuantityArray2: array[3] of Decimal; var CurrentSignFactor2: Integer; var InsertIsBlocked2: Boolean; var DeleteIsBlocked2: Boolean; var BlockCommit2: Boolean)
    begin
        TempTrackingSpecInsert2.DeleteAll();
        TempTrackingSpecInsert2.Reset();
        TempItemTrackLineInsert.Reset();
        if TempItemTrackLineInsert.Find('-') then
            repeat
                TempTrackingSpecInsert2.Init();
                TempTrackingSpecInsert2 := TempItemTrackLineInsert;
                TempTrackingSpecInsert2.Insert();
            until TempItemTrackLineInsert.Next = 0;

        TempTrackingSpecModify2.DeleteAll();
        TempTrackingSpecModify2.Reset();
        TempItemTrackLineModify.Reset();
        if TempItemTrackLineModify.Find('-') then
            repeat
                TempTrackingSpecModify2.Init();
                TempTrackingSpecModify2 := TempItemTrackLineModify;
                TempTrackingSpecModify2.Insert();
            until TempItemTrackLineModify.Next = 0;

        TempTrackingSpecDelete2.DeleteAll();
        TempTrackingSpecDelete2.Reset();
        TempItemTrackLineDelete.Reset();
        if TempItemTrackLineDelete.Find('-') then
            repeat
                TempTrackingSpecDelete2.Init();
                TempTrackingSpecDelete2 := TempItemTrackLineDelete;
                TempTrackingSpecDelete2.Insert();
            until TempItemTrackLineDelete.Next = 0;

        Item2 := Item;
        CopyArray(UndefinedQtyArray2, UndefinedQtyArray, 1);
        CopyArray(SourceQuantityArray2, SourceQuantityArray, 1);
        CurrentSignFactor2 := CurrentSignFactor;
        InsertIsBlocked2 := InsertIsBlocked;
        DeleteIsBlocked2 := DeleteIsBlocked;
        BlockCommit2 := BlockCommit;
    end;

    procedure SetVariables(var TempTrackingSpecInsert2: Record "Tracking Specification" temporary; var TempTrackingSpecModify2: Record "Tracking Specification" temporary; var TempTrackingSpecDelete2: Record "Tracking Specification" temporary)
    begin
        TempItemTrackLineInsert.DeleteAll();
        TempItemTrackLineInsert.Reset();
        TempTrackingSpecInsert2.Reset();
        if TempTrackingSpecInsert2.Find('-') then
            repeat
                TempItemTrackLineInsert.Init();
                TempItemTrackLineInsert := TempTrackingSpecInsert2;
                TempItemTrackLineInsert.Insert();
            until TempTrackingSpecInsert2.Next = 0;

        TempItemTrackLineModify.DeleteAll();
        TempItemTrackLineModify.Reset();
        TempTrackingSpecModify2.Reset();
        if TempTrackingSpecModify2.Find('-') then
            repeat
                TempItemTrackLineModify.Init();
                TempItemTrackLineModify := TempTrackingSpecModify2;
                TempItemTrackLineModify.Insert();
            until TempTrackingSpecModify2.Next = 0;

        TempItemTrackLineDelete.DeleteAll();
        TempItemTrackLineDelete.Reset();
        TempTrackingSpecDelete2.Reset();
        if TempTrackingSpecDelete2.Find('-') then
            repeat
                TempItemTrackLineDelete.Init();
                TempItemTrackLineDelete := TempTrackingSpecDelete2;
                TempItemTrackLineDelete.Insert();
            until TempTrackingSpecDelete2.Next = 0;
    end;

    local procedure GetHandleSource(TrackingSpecification: Record "Tracking Specification"): Boolean
    var
        WhseActivLine: Record "Warehouse Activity Line";
        QtyToHandleColumnIsHidden: Boolean;
    begin
        with TrackingSpecification do begin
            if ("Source Type" = DATABASE::"Item Journal Line") and ("Source Subtype" = 6) then begin // 6 => Prod.order line directly
                ProdOrderLineHandling := true;
                exit(true);  // Display Handle column for prod. orders
            end;

            // Prod. order line via inventory put-away
            if "Source Type" = DATABASE::"Prod. Order Line" then begin
                WhseActivLine.SetSourceFilter("Source Type", "Source Subtype", "Source ID", "Source Prod. Order Line", "Source Ref. No.", true);
                WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Invt. Put-away");
                if not WhseActivLine.IsEmpty then begin
                    ProdOrderLineHandling := true;
                    exit(true);
                end;
            end;

            QtyToHandleColumnIsHidden :=
              ("Source Type" in
               [DATABASE::"Item Ledger Entry",
                DATABASE::"Item Journal Line",
                DATABASE::"Job Journal Line",
                DATABASE::"Requisition Line"]) or
              (("Source Type" in [DATABASE::"Sales Line", DATABASE::"Purchase Line", DATABASE::"Service Line"]) and
               ("Source Subtype" in [0, 2, 3])) or
              (("Source Type" = DATABASE::"Assembly Line") and ("Source Subtype" = 0));
        end;
        OnAfterGetHandleSource(TrackingSpecification, QtyToHandleColumnIsHidden);
        exit(not QtyToHandleColumnIsHidden);
    end;

    local procedure GetInvoiceSource(TrackingSpecification: Record "Tracking Specification"): Boolean
    var
        QtyToInvoiceColumnIsHidden: Boolean;
    begin
        with TrackingSpecification do begin
            QtyToInvoiceColumnIsHidden :=
              ("Source Type" in
               [DATABASE::"Item Ledger Entry",
                DATABASE::"Item Journal Line",
                DATABASE::"Job Journal Line",
                DATABASE::"Requisition Line",
                DATABASE::"Transfer Line",
                DATABASE::"Assembly Line",
                DATABASE::"Assembly Header",
                DATABASE::"Prod. Order Line",
                DATABASE::"Prod. Order Component"]) or
              (("Source Type" in [DATABASE::"Sales Line", DATABASE::"Purchase Line", DATABASE::"Service Line"]) and
               ("Source Subtype" in [0, 2, 3, 4]))
        end;
        OnAfterGetInvoiceSource(TrackingSpecification, QtyToInvoiceColumnIsHidden);
        exit(not QtyToInvoiceColumnIsHidden);
    end;

    procedure GetTrackingSpec(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        TempTrackingSpecification.DeleteAll();

        if FindSet then
            repeat
                TempTrackingSpecification := Rec;
                TempTrackingSpecification.Insert();
            until Next = 0;
    end;

    procedure SetSecondSourceID(SourceID: Integer; IsATO: Boolean)
    begin
        SecondSourceID := SourceID;
        IsAssembleToOrder := IsATO;
    end;

    local procedure SynchronizeWarehouseItemTracking()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Location: Record Location;
        WarehouseEntry: Record "Warehouse Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseManagement: Codeunit "Whse. Management";
    begin
        if ItemTrackingMgt.ItemTrkgIsManagedByWhse(
             "Source Type", "Source Subtype", "Source ID",
             "Source Prod. Order Line", "Source Ref. No.", "Location Code", "Item No.")
        then
            exit;

        WhseManagement.SetSourceFilterForWhseShptLine(
          WarehouseShipmentLine, "Source Type", "Source Subtype", "Source ID", "Source Ref. No.", true);
        if WarehouseShipmentLine.IsEmpty then
            exit;

        WarehouseShipmentLine.FindSet;
        if not (Location.RequirePicking("Location Code") and Location.RequirePutaway("Location Code")) then begin
            WarehouseEntry.SetSourceFilter("Source Type", "Source Subtype", "Source ID", "Source Ref. No.", true);
            WarehouseEntry.SetFilter(
              "Reference Document", '%1|%2',
              WarehouseEntry."Reference Document"::"Put-away", WarehouseEntry."Reference Document"::Pick);
            if not WarehouseEntry.IsEmpty then
                exit;
        end;
        repeat
            WarehouseShipmentLine.DeleteWhseItemTrackingLines;
            WarehouseShipmentLine.CreateWhseItemTrackingLines;
        until WarehouseShipmentLine.Next = 0;
    end;

    local procedure IsOrderToOrderBindingToTransfer(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if CurrentSourceType = DATABASE::"Transfer Line" then
            exit(false);

        ReservEntry.SetSourceFilter("Source Type", "Source Subtype", "Source ID", "Source Ref. No.", false);
        ReservEntry.SetSourceFilter("Source Batch Name", "Source Prod. Order Line");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.SetRange(Binding, ReservEntry.Binding::"Order-to-Order");
        if ReservEntry.IsEmpty then
            exit(false);

        ReservEntry.FindFirst;
        ReservEntry.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
        if not ((ReservEntry."Source Type" = DATABASE::"Transfer Line") and (ReservEntry."Source Subtype" = 0)) then
            exit(false);

        CurrentSourceRowID :=
          ItemTrackingMgt.ComposeRowID(ReservEntry."Source Type",
            0, ReservEntry."Source ID", ReservEntry."Source Batch Name",
            ReservEntry."Source Prod. Order Line", ReservEntry."Source Ref. No.");
        SecondSourceRowID :=
          ItemTrackingMgt.ComposeRowID(ReservEntry."Source Type",
            1, ReservEntry."Source ID", ReservEntry."Source Batch Name",
            ReservEntry."Source Prod. Order Line", ReservEntry."Source Ref. No.");
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingSpec(var SourceTrackingSpec: Record "Tracking Specification"; var DestTrkgSpec: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTrackingSpec(var OldTrkgSpec: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateReservEntryFor(var OldTrackingSpecification: Record "Tracking Specification"; var NewTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEntriesAreIdentical(ReservEntry1: Record "Reservation Entry"; ReservEntry2: Record "Reservation Entry"; var IdenticalArray: array[2] of Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveFields(var TrkgSpec: Record "Tracking Specification"; var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignNewTrackingNo(var TrkgSpec: Record "Tracking Specification"; xTrkgSpec: Record "Tracking Specification"; FieldID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetHandleSource(TrackingSpecification: Record "Tracking Specification"; var QtyToHandleColumnIsHidden: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetInvoiceSource(TrackingSpecification: Record "Tracking Specification"; var QtyToInvoiceColumnIsHidden: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisterItemTrackingLines(var TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var CurrTrackingSpecification: Record "Tracking Specification"; var AvailabilityDate: Date)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterSetControls(ItemTrackingCode: Record "Item Tracking Code"; var Controls: Option Handle,Invoice,Quantity,Reclass,Tracking; var SetAccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceSpec(var TrackingSpecification: Record "Tracking Specification"; var CurrTrackingSpecification: Record "Tracking Specification"; var AvailabilityDate: Date; var BlockCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSynchronizeLinkedSources(FormRunMode: Option ,Reclass,"Combined Ship/Rcpt","Drop Shipment",Transfer; CurrentSourceType: Integer; CurrentSourceRowID: Text[250]; SecondSourceRowID: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignLotNoOnAfterInsert(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignSerialNoBatchOnAfterInsert(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddToGlobalRecordSet(var TrackingSpecification: Record "Tracking Specification"; EntriesExist: Boolean; CurrentSignFactor: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignNewLotNo(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClosePage(var TrackingSpecification: Record "Tracking Specification"; var SkipWriteToDatabase: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRecord(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLotNoAssistEdit(var TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSerialNoAssistEdit(var TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSerialNoOnAfterValidate(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSourceSpec(var TrackingSpecification: Record "Tracking Specification"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecondSourceQuantity(var SecondSourceQuantityArray: array[3] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCollectTempTrackingSpecificationInsert(var TempTrackingSpecification: Record "Tracking Specification" temporary; ItemLedgerEntry: Record "Item Ledger Entry"; var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUndefinedQty(var TrackingSpecification: Record "Tracking Specification"; var TotalItemTrackingSpecification: Record "Tracking Specification"; var UndefinedQtyArray: array[3] of Decimal; var SourceQuantityArray: array[5] of Decimal; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWriteToDatabase(var TrackingSpecification: Record "Tracking Specification"; var CurrentPageIsOpen: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddReservEntriesToTempRecSetOnBeforeInsert(var TempTrackingSpecification: Record "Tracking Specification" temporary; ReservationEntry: Record "Reservation Entry"; SwapSign: Boolean; Color: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertRecordOnBeforeTempItemTrackLineInsert(var TempTrackingSpecificationInsert: Record "Tracking Specification" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterChangeOnAfterCreateReservEntry(var ReservEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification"; OldTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterChangeOnAfterFullDelete(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterChangeOnAfterModify(var NewTrackingSpecification: Record "Tracking Specification"; var OldTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectEntriesOnAfterTransferFields(var TempTrackingSpec: Record "Tracking Specification" temporary; var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetQtyToHandleAndInvoiceOnBeforeReservEntryModify(var ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetQtyToHandleAndInvoiceOnBeforeTrackingSpecModify(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetSourceSpecOnAfterAssignCurrentEntryStatus(var TrackingSpecification: Record "Tracking Specification"; var CurrentEntryStatus: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWriteToDatabaseOnBeforeRegisterDecrease(var TempTrackingSpecificationModify: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWriteToDatabaseOnBeforeRegisterInsert(var TempTrackingSpecificationInsert: Record "Tracking Specification" temporary)
    begin
    end;
}

