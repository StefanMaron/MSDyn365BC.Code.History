page 7375 "Inventory Put-away"
{
    Caption = 'Inventory Put-away';
    PageType = Document;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = "Warehouse Activity Header";
    SourceTableView = WHERE(Type = CONST("Invt. Put-away"));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location where the warehouse activity takes place.';
                }
                field(SourceDocument; "Source Document")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the type of document that the line relates to.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CODEUNIT.Run(CODEUNIT::"Create Inventory Put-away", Rec);
                        CurrPage.WhseActivityLines.PAGE.UpdateForm();
                    end;

                    trigger OnValidate()
                    begin
                        SourceNoOnAfterValidate();
                    end;
                }
                field("Destination No."; Rec."Destination No.")
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaptionClass("Destination Type", "Source Document", 0));
                    Editable = false;
                    ToolTip = 'Specifies the number or the code of the customer or vendor that the line is linked to.';
                }
                field("WMSMgt.GetDestinationName(""Destination Type"",""Destination No."")"; WMSMgt.GetDestinationEntityName("Destination Type", "Destination No."))
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaptionClass("Destination Type", "Source Document", 1));
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the received items put away into storage.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the warehouse activity should be recorded as being posted.';
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the date you expect the items to be available in your warehouse. If you leave the field blank, it will be calculated as follows: Planned Receipt Date + Safety Lead Time + Inbound Warehouse Handling Time = Expected Receipt Date.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaptionClass("Destination Type", "Source Document", 2));
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("External Document No.2"; Rec."External Document No.2")
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaptionClass("Destination Type", "Source Document", 3));
                    ToolTip = 'Specifies an additional part of the document number that refers to the customer''s or vendor''s numbering system.';
                }
            }
            part(WhseActivityLines; "Invt. Put-away Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "Activity Type" = FIELD(Type),
                              "No." = FIELD("No.");
                SubPageView = SORTING("Activity Type", "No.", "Sorting Sequence No.")
                              WHERE(Breakbulk = CONST(false));
            }
        }
        area(factboxes)
        {
            part(Control7; "Lot Numbers by Bin FactBox")
            {
                ApplicationArea = ItemTracking;
                Provider = WhseActivityLines;
                SubPageLink = "Item No." = FIELD("Item No."),
                              "Variant Code" = FIELD("Variant Code"),
                              "Location Code" = FIELD("Location Code");
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Put-&away")
            {
                Caption = 'Put-&away';
                Image = CreatePutAway;
#if not CLEAN19
                action(List)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all warehouse documents of this type that exist.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by platform capabilities.';
                    ObsoleteTag = '19.0';

                    trigger OnAction()
                    begin
                        LookupActivityHeader("Location Code", Rec);
                    end;
                }
#endif
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Whse. Activity Header"),
                                  Type = FIELD(Type),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Posted Put-aways")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Put-aways';
                    Image = PostedPutAway;
                    RunObject = Page "Posted Invt. Put-away List";
                    RunPageLink = "Invt. Put-away No." = FIELD("No.");
                    RunPageView = SORTING("Invt. Put-away No.");
                    ToolTip = 'View any quantities that have already been put away.';
                }
                action("Source Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Source Document';
                    Image = "Order";
                    ToolTip = 'View the source document of the warehouse activity.';

                    trigger OnAction()
                    var
                        WMSMgt: Codeunit "WMS Management";
                    begin
                        WMSMgt.ShowSourceDocCard("Source Type", "Source Subtype", "Source No.");
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
                action(GetSourceDocument)
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Get Source Document';
                    Ellipsis = true;
                    Image = GetSourceDoc;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'Select the source document that you want to put items away for.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Create Inventory Put-away", Rec);
                    end;
                }
                action("Autofill Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Autofill Qty. to Handle';
                    Image = AutofillQtyToHandle;
                    ToolTip = 'Have the system enter the outstanding quantity in the Qty. to Handle field.';

                    trigger OnAction()
                    begin
                        AutofillQtyToHandle();
                    end;
                }
                action("Delete Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Delete Qty. to Handle';
                    Image = DeleteQtyToHandle;
                    ToolTip = 'Have the system clear the value in the Qty. To Handle field. ';

                    trigger OnAction()
                    begin
                        DeleteQtyToHandle();
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        PostPutAwayYesNo();
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        PostAndPrint();
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    WhseActPrint.PrintInvtPutAwayHeader(Rec, false);
                end;
            }
        }
        area(reporting)
        {
            action("Put-away List")
            {
                ApplicationArea = Warehouse;
                Caption = 'Put-away List';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Put-away List";
                ToolTip = 'View or print a detailed list of items that must be put away.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                group(Category_Category5)
                {
                    Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 4.';
                    ShowAs = SplitButton;

                    actionref("P&ost_Promoted"; "P&ost")
                    {
                    }
                    actionref("Post and &Print_Promoted"; "Post and &Print")
                    {
                    }
                }
                group("Category_Qty. to Handle")
                {
                    Caption = 'Qty. to Handle';
                    ShowAs = SplitButton;

                    actionref("Autofill Qty. to Handle_Promoted"; "Autofill Qty. to Handle")
                    {
                    }
                    actionref("Delete Qty. to Handle_Promoted"; "Delete Qty. to Handle")
                    {
                    }
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref(GetSourceDocument_Promoted; GetSourceDocument)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Location Code" := GetUserLocation();
    end;

    trigger OnOpenPage()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        ErrorIfUserIsNotWhseEmployee();
        FilterGroup(2); // set group of filters user cannot change
        SetFilter("Location Code", WMSManagement.GetWarehouseEmployeeLocationFilter(UserId));
        FilterGroup(0); // set filter group back to standard
    end;

    var
        WMSMgt: Codeunit "WMS Management";
        WhseActPrint: Codeunit "Warehouse Document-Print";

    local procedure AutofillQtyToHandle()
    begin
        CurrPage.WhseActivityLines.PAGE.AutofillQtyToHandle();
    end;

    local procedure DeleteQtyToHandle()
    begin
        CurrPage.WhseActivityLines.PAGE.DeleteQtyToHandle();
    end;

    local procedure PostPutAwayYesNo()
    begin
        CurrPage.WhseActivityLines.PAGE.PostPutAwayYesNo();
    end;

    local procedure PostAndPrint()
    begin
        CurrPage.WhseActivityLines.PAGE.PostAndPrint();
    end;

    local procedure SourceNoOnAfterValidate()
    begin
        CurrPage.WhseActivityLines.PAGE.UpdateForm();
    end;
}

