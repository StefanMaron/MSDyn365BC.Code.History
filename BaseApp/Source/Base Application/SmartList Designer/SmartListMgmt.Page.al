#if not CLEAN19
page 9888 "SmartList Mgmt"
{
    Caption = 'SmartList Management';
    Editable = false;
    Extensible = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Designed Query Management";
    ObsoleteState = Pending;
    ObsoleteReason = 'The SmartList Designer is not supported in Business Central.';
    ObsoleteTag = '19.0';

    layout
    {
        area(Content)
        {
            repeater(Repeater)
            {
                Editable = false;

                field("Object ID"; "Object ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the object ID.';
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the SmartList name.';
                }
                // Removed for now, may resurface later
                // field(Group; Group)
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the group.';
                // }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description.';
                }
                field(Categories; Categories)
                {
                    ApplicationArea = All;
                    Caption = 'Assigned List Pages';
                    ToolTip = 'Specifies the list pages that the SmartList is assigned to.';
                }
                field("Primary Source Table"; "Primary Source Table")
                {
                    ApplicationArea = All;
                    Caption = 'Primary Table';
                    ToolTip = 'Specifies the primary table of the SmartList.';
                }

                field("Modified By"; ModifiedBy)
                {
                    ApplicationArea = All;
                    Caption = 'Modified By';
                    ToolTip = 'Specifies the user who last modified the SmartList.';
                }

                field("Modified Date"; ModifiedDate)
                {
                    ApplicationArea = All;
                    Caption = 'Modified Date';
                    ToolTip = 'Specifies the date and time that the SmartList was last modified.';
                }
            }
        }

        area(FactBoxes)
        {
            part(ImportPart; "SmartList Import FactBox")
            {
            }
            part(ExportPart; "SmartList Export FactBox")
            {
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Actions")
            {
                Caption = 'Actions';

                action("New")
                {
                    ApplicationArea = All;
                    Image = Add;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Create a SmartList query.';

                    trigger OnAction()
                    var
                        Designer: Codeunit "SmartList Designer";
                    begin
                        Designer.RunForNew();
                    end;
                }
                action("Delete")
                {
                    ApplicationArea = All;
                    Image = Delete;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Scope = Repeater;
                    ToolTip = 'Delete selected SmartList queries.';

                    trigger OnAction()
                    var
                        QueryManagement: Record "Designed Query Management";
                    begin
                        CurrPage.SetSelectionFilter(QueryManagement);
                        if QueryManagement.IsEmpty() then
                            exit;

                        if QueryManagement.FindSet() and Confirm(ConfirmDeleteQueryTxt, false, Rec."Object ID", Rec."Object Name") then
                            repeat
                                QueryManagement.Delete();
                            until QueryManagement.Next() = 0;
                    end;
                }

                action("Edit")
                {
                    ApplicationArea = All;
                    Image = Edit;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Scope = Repeater;
                    ToolTip = 'Edit a SmartList query.';
                    Enabled = RecordsExist;

                    trigger OnAction()
                    var
                        Designer: Codeunit "SmartList Designer";
                    begin
                        Designer.RunForQuery(Rec."Unique ID");
                    end;
                }
                action("Preview")
                {
                    ApplicationArea = All;
                    Image = View;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Scope = Repeater;
                    ToolTip = 'Preview a SmartList query.';
                    Enabled = RecordsExist;

                    trigger OnAction()
                    begin
                        Hyperlink(GetUrl(ClientType::Web, CurrentCompany(), ObjectType::Query, Rec."Object ID"));
                    end;
                }
                action("Export")
                {
                    ApplicationArea = All;
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Scope = Repeater;
                    ToolTip = 'Export SmartList queries.';
                    Enabled = RecordsExist;

                    trigger OnAction()
                    var
                        QueryManagement: Record "Designed Query Management";
                        ResultsRec: Record "SmartList Export Results";
                        Management: Codeunit "SmartList Mgmt";
                        ExportDialog: Page "SmartList Export Dialog";
                        Filename: Text;
                    begin
                        if not Management.DoesUserHaveImportExportAccess(UserSecurityId()) then
                            Error(UserDoesNotHaveImportExportAccessErr);

                        // Prompt the user for a filename. A default is provided in the dialog, but the user can
                        // change it to be whatever they want.
                        ExportDialog.LookupMode(true);
                        if ExportDialog.RunModal() = Action::LookupCancel then
                            exit;
                        Filename := ExportDialog.GetFilename() + '.sld';

                        CurrPage.SetSelectionFilter(QueryManagement);
                        if QueryManagement.IsEmpty() then
                            exit;
                        Management.ExportQueries(QueryManagement, Filename);

                        // The results are populated by the export process
                        ResultsRec.Init();
                        if not ResultsRec.IsEmpty() then
                            Page.Run(Page::"SmartList Export Results", ResultsRec);

                        UpdateFactBoxes();
                    end;
                }
                action("Import")
                {
                    ApplicationArea = All;
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Scope = Repeater;
                    ToolTip = 'Import SmartList queries.';

                    trigger OnAction()
                    var
                        ResultsRec: Record "SmartList Import Results";
                        ArchiveBlob: Codeunit "Temp Blob";
                        FileMgt: Codeunit "File Management";
                        Management: Codeunit "SmartList Mgmt";
                        ArchiveStream: InStream;
                    begin
                        if not Management.DoesUserHaveImportExportAccess(UserSecurityId()) then
                            Error(UserDoesNotHaveImportExportAccessErr);

                        if FileMgt.BLOBImportWithFilter(ArchiveBlob, 'Import', '', 'SLD Files (*.sld)|*.sld', '.sld') = '' then
                            exit;
                        ArchiveBlob.CreateInStream(ArchiveStream);

                        Management.ImportQueries(ArchiveStream);

                        // The results are populated by the import process
                        ResultsRec.Init();
                        if not ResultsRec.IsEmpty() then
                            Page.Run(Page::"SmartList Import Results", ResultsRec);

                        UpdateFactBoxes();
                    end;
                }
                action("Assign Permissions")
                {
                    ApplicationArea = All;
                    Image = Permission;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Assign one or more permission sets.';
                    Enabled = RecordsExist;

                    trigger OnAction()
                    var
                        QueryManagement: Record "Designed Query Management";
                        PermissionManagement: Page "SmartList Permission Mgmt";
                    begin
                        CurrPage.SetSelectionFilter(QueryManagement);
                        PermissionManagement.SetManagementRecords(QueryManagement);
                        PermissionManagement.LookupMode(true);
                        PermissionManagement.RunModal();
                    end;
                }
                // Removed for now, may resurface later
                // action("Assign Group")
                // {
                //     ApplicationArea = All;
                //     Promoted = true;
                //     PromotedCategory = Process;
                //     PromotedIsBig = true;
                //     PromotedOnly = true;
                //     ToolTip = 'Assign a group to a SmartList query.';
                //     Enabled = RecordsExist;
                //     trigger OnAction()
                //     var
                //         QueryManagement: Record "Designed Query Management";
                //         GroupManagement: Page "SmartList Group Mgmt";
                //     begin
                //         CurrPage.SetSelectionFilter(QueryManagement);
                //         GroupManagement.SetManagementRecords(QueryManagement);
                //         GroupManagement.LookupMode(true);
                //         GroupManagement.RunModal();
                //     end;
                // }
                action(Navigations)
                {
                    Caption = 'Navigation';
                    ApplicationArea = All;
                    Image = Links;
                    Scope = Repeater;
                    Promoted = true;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    PromotedCategory = Process;
                    ToolTip = 'Manage Query Navigation action definitions.';
                    Enabled = RecordsExist;

                    trigger OnAction()
                    var
                        QueryNavigationList: Page "Query Navigation List";
                    begin
                        QueryNavigationList.OpenForQuery(Rec."Object ID", rec."Object Name");
                    end;
                }
            }
        }
    }

    views
    {
        view(Finance)
        {
            Caption = 'Finance';
            Filters = where(Categories = filter('@*Chart of Accounts*'));
        }
        view(Inventory)
        {
            Caption = 'Inventory';
            Filters = where(Categories = filter('@*Item List*'));
        }
        view(Purchasing)
        {
            Caption = 'Purchasing';
            Filters = where(Categories = filter('@*Blanket Purchase Orders*|@*Posted Purchase Credit Memos*|@*Posted Purchase Invoices*|@*Posted Purchase Receipts*|@*Purchase Credit Memos*|@*Purchase Invoices*|@*Purchase Order List*|@*Purchase Quotes*|@*Vendor List*'));
        }
        view(Sales)
        {
            Caption = 'Sales';
            Filters = where(Categories = filter('@*Customer List*|@*Blanket Sales Orders*|@*Posted Sales Credit Memos*|@*Posted Sales Invoices*|@*Posted Sales Invoices*|@*Sales Credit Memos*|@*Sales Invoice List*|@*Sales Order List*|@*Sales Quotes*|@*Sales Return Order List*'));
        }
    }

    trigger OnOpenPage()
    begin
        if not SmartListManagement.DoesUserHaveManagementAccess(UserSecurityId()) then
            Error(UserDoesNotHaveManagementAccessErr);

        UpdateFactBoxes();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        RecordsExist := false;
        if not SmartListDesigner.DoesUserHaveAPIAccess(UserSecurityId()) then
            Error(UserDoesNotHaveDeleteAccessErr);
    end;

    trigger OnAfterGetRecord()
    var
        designedQueryRec: Record "Designed Query";
        userRec: Record "User";
    begin
        RecordsExist := true;
        Clear(ModifiedBy);
        Clear(ModifiedDate);

        designedQueryRec.SetRange("Query ID", Rec."Query ID");
        if designedQueryRec.FindFirst() then begin
            userRec.SetRange("User Security ID", designedQueryRec.SystemCreatedBy);
            if userRec.FindFirst() then begin
                ModifiedBy := userRec."User Name";
                ModifiedDate := designedQueryRec.SystemModifiedAt
            end;
        end;
    end;

    local procedure UpdateFactBoxes()
    var
        ImportResults: Record "SmartList Import Results";
        ExportResults: Record "SmartList Export Results";
    begin
        ImportResults.Init();
        ExportResults.Init();
        CurrPage.ImportPart.Page.UpdateData(ImportResults);
        CurrPage.ExportPart.Page.UpdateData(ExportResults);
    end;

    var
        SmartListDesigner: Codeunit "SmartList Designer";
        SmartListManagement: Codeunit "SmartList Mgmt";
        ConfirmDeleteQueryTxt: Label 'Delete selected SmartList Queries?';
        UserDoesNotHaveManagementAccessErr: Label 'You do not have permission to manage SmartLists. Contact your system administrator.';
        UserDoesNotHaveImportExportAccessErr: Label 'You do not have permission to import or export SmartLists. Contact your system administrator.';
        UserDoesNotHaveDeleteAccessErr: Label 'You do not have permission to delete a SmartList. Contact your system administrator.';
        RecordsExist: Boolean;
        ModifiedBy: Text;
        ModifiedDate: DateTime;
}
#endif