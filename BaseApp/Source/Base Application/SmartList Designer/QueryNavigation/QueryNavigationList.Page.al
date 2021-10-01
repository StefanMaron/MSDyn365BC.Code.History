#if not CLEAN19
page 988 "Query Navigation List"
{
    PageType = List;
    SourceTable = "Query Navigation";
    Extensible = false;
    Editable = false;
    RefreshOnActivate = true;
    Caption = 'Query Navigation List';
    ObsoleteReason = 'The SmartList Designer is not supported in Business Central';
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the Navigation.';
                    Style = Unfavorable;
                    StyleExpr = IsInvalid;
                }

                field(TargetPageId; Rec."Target Page Id")
                {
                    ApplicationArea = All;
                    Caption = 'Target Page Id';
                    ToolTip = 'Specifies the ID of the page that will be opened by the Navigation.';
                }

                field(TargetPageName; TargetPageName)
                {
                    ApplicationArea = All;
                    Caption = 'Target Page Name';
                    ToolTip = 'Specifies the name of the page that will be opened by the Navigation.';
                }

                field(LinkingDataItem; Rec."Linking Data Item Name")
                {
                    ApplicationArea = All;
                    Caption = 'Linking Data Item';
                    ToolTip = 'Specifies what Data Item on the query will be used to generate filters for the target page.';
                }

                field("Default Link"; Rec."Default")
                {
                    ApplicationArea = All;
                    Caption = 'Default Link';
                    ToolTip = 'Specifies if the Navigation should be the displayed as a link on each row of the query.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Create)
            {
                ApplicationArea = All;
                Caption = 'Create';
                ToolTip = 'Create a new Navigation';
                Image = Add;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Builder: Page "Query Navigation Builder";
                begin
                    Builder.OpenForCreatingNewNavigation(SourceQueryObjectId);
                end;
            }

            action(Edit)
            {
                ApplicationArea = All;
                Caption = 'Edit';
                ToolTip = 'Edit the currently selected Navigation.';
                Image = Edit;
                Enabled = RecordsExist;
                Scope = Repeater;
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Builder: Page "Query Navigation Builder";
                begin
                    Builder.OpenForEditingExistingNavigation(Rec);
                end;
            }

            action(Delete)
            {
                ApplicationArea = All;
                Caption = 'Delete';
                ToolTip = 'Delete the currently selected Navigation.';
                Image = Delete;
                Scope = Repeater;
                Enabled = RecordsExist;
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    if Confirm(DeleteItemConfirmTxt, false, Rec.Id, Rec.Name) then
                        Rec.Delete();

                    RecordsExist := false;
                    CurrPage.Update(true);
                end;
            }

            action(SetDefault)
            {
                ApplicationArea = All;
                Caption = 'Use as default';
                ToolTip = 'Set the selected Navigation as the one that is displayed as a link for each row of the query.';
                Image = Default;
                Enabled = RecordsExist;
                Scope = Repeater;
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    OtherNavigationMetadataRec: Record "Query Navigation";
                begin
                    Rec.Default := true;
                    Rec.Modify();

                    OtherNavigationMetadataRec.SetRange("Source Query Object Id", Rec."Source Query Object Id");
                    OtherNavigationMetadataRec.SetRange(Default, true);
                    OtherNavigationMetadataRec.SetFilter(Id, '<>%1', Rec.Id);

                    if OtherNavigationMetadataRec.FindSet() then
                        repeat
                            OtherNavigationMetadataRec.Default := false;
                            OtherNavigationMetadataRec.Modify();
                        until OtherNavigationMetadataRec.Next() = 0;

                    CurrPage.Update();
                end;
            }
        }
    }

    internal procedure OpenForQuery(QueryObjectId: Integer; QueryName: Text)
    begin
        SourceQueryObjectId := QueryObjectId;
        CurrPage.Caption(StrSubstNo(CaptionTxt, QueryName));
        CurrPage.Run();
    end;

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Source Query Object Id", SourceQueryObjectId);
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetRecord()
    var
        ignored: Record "Query Navigation Validation";
        PageMetadata: Record "Page Metadata";
        QueryNavigationValidation: Codeunit "Query Navigation Validation";
    begin
        IsInvalid := not QueryNavigationValidation.ValidateNavigation(Rec, ignored);
        RecordsExist := true;

        PageMetadata.SetRange(ID, Rec."Target Page Id");
        if PageMetadata.FindFirst() then
            TargetPageName := PageMetadata.Caption;
    end;

    var
        CaptionTxt: Label '%1 - Navigation List', Comment = '%1 = name of a query';
        DeleteItemConfirmTxt: Label 'Delete Navigation %1 - %2?', Comment = '%1 = Id of Navigation, %2 = Name of Navigation';
        SourceQueryObjectId: Integer;
        IsInvalid: Boolean;
        TargetPageName: Text;
        RecordsExist: Boolean;
}
#endif