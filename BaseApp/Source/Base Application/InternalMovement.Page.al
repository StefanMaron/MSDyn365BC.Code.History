page 7399 "Internal Movement"
{
    Caption = 'Internal Movement';
    PageType = Document;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Internal Movement Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit then
                            CurrPage.Update;
                    end;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location where the internal movement is being performed.';
                }
                field("To Bin Code"; "To Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where you want items on this internal movement to be placed when they are picked.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the warehouse activity must be completed.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Assignment Date"; "Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the date when the user was assigned the activity.';
                }
                field("Assignment Time"; "Assignment Time")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the time when the user was assigned the activity.';
                }
                field("Sorting Method"; "Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the internal movements are sorted.';

                    trigger OnValidate()
                    begin
                        SortingMethodOnAfterValidate;
                    end;
                }
            }
            part(InternalMovementLines; "Internal Movement Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "No." = FIELD("No.");
                SubPageView = SORTING("No.", "Sorting Sequence No.");
            }
        }
        area(factboxes)
        {
            part(Control5; "Lot Numbers by Bin FactBox")
            {
                ApplicationArea = ItemTracking;
                Provider = InternalMovementLines;
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
            group("&Internal Movement")
            {
                Caption = '&Internal Movement';
                Image = CreateMovement;
                action(List)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all warehouse documents of this type that exist.';

                    trigger OnAction()
                    begin
                        LookupInternalMovementHeader(Rec);
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Internal Movement"),
                                  Type = CONST(" "),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Get Bin Content")
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Get Bin Content';
                    Ellipsis = true;
                    Image = GetBinContent;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Use a function to create transfer lines with items to put away or pick based on the actual content in the specified bin.';

                    trigger OnAction()
                    var
                        BinContent: Record "Bin Content";
                        WhseGetBinContent: Report "Whse. Get Bin Content";
                    begin
                        TestField("No.");
                        TestField("Location Code");
                        BinContent.SetRange("Location Code", "Location Code");
                        WhseGetBinContent.SetTableView(BinContent);
                        WhseGetBinContent.InitializeInternalMovement(Rec);
                        WhseGetBinContent.Run;
                    end;
                }
                action("Create Inventory Movement")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Inventory Movement';
                    Ellipsis = true;
                    Image = CreatePutAway;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create an inventory movement to handle items on the document according to a basic warehouse configuration.';

                    trigger OnAction()
                    var
                        CreateInvtPickMovement: Codeunit "Create Inventory Pick/Movement";
                    begin
                        CreateInvtPickMovement.CreateInvtMvntWithoutSource(Rec);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        OpenInternalMovementHeader(Rec);
    end;

    local procedure SortingMethodOnAfterValidate()
    begin
        CurrPage.Update;
    end;
}

