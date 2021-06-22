page 99000809 "Production BOM Version"
{
    Caption = 'Production BOM Version';
    DataCaptionExpression = Caption;
    PageType = ListPlus;
    SourceTable = "Production BOM Version";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Version Code"; "Version Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the version code of the production BOM.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description for the production BOM version.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of this production BOM version.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting date for this production BOM version.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies when the production BOM version card was last modified.';
                }
            }
            part(ProdBOMLine; "Production BOM Version Lines")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Production BOM No." = FIELD("Production BOM No."),
                              "Version Code" = FIELD("Version Code");
                SubPageView = SORTING("Production BOM No.", "Version Code", "Line No.");
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
            group("Ve&rsion")
            {
                Caption = 'Ve&rsion';
                Image = Versions;
                action("Where-Used")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Where-Used';
                    Image = "Where-Used";
                    ToolTip = 'View a list of BOMs in which the item is used.';

                    trigger OnAction()
                    var
                        ProdBOMHeader: Record "Production BOM Header";
                        ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
                    begin
                        ProdBOMHeader.Get("Production BOM No.");
                        ProdBOMWhereUsed.SetProdBOM(ProdBOMHeader, "Starting Date");
                        ProdBOMWhereUsed.Run;
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
                action(CopyBOM)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy &BOM';
                    Image = CopyBOMHeader;
                    ToolTip = 'Copy an existing production BOM to quickly create a similar BOM.';

                    trigger OnAction()
                    begin
                        if not Confirm(Text000, false) then
                            exit;

                        ProdBOMHeader.Get("Production BOM No.");
                        ProductionBOMCopy.CopyBOM("Production BOM No.", '', ProdBOMHeader, "Version Code");
                    end;
                }
                action("Copy BOM &Version")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy BOM &Version';
                    Ellipsis = true;
                    Image = CopyBOMVersion;
                    ToolTip = 'Copy an existing production BOM version to quickly create a similar BOM.';

                    trigger OnAction()
                    begin
                        ProductionBOMCopy.CopyFromVersion(Rec);
                    end;
                }
            }
        }
    }

    var
        Text000: Label 'Copy from Production BOM?';
        ProdBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
}

