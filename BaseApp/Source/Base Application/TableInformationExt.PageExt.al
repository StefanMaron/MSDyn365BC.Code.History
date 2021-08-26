pageextension 8700 "Table Information Ext." extends "Table Information"
{
    PromotedActionCategories = 'New,Process,Report,Navigate';

    actions
    {
        addlast(Navigation)
        {
            action("Data Administration")
            {
                Caption = 'Data Administration';
                ToolTip = 'Navigate to the Data Administration page to manage settings for deleting and compressing data.';
                ApplicationArea = All;
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;
                PromotedCategory = Category4;
                Image = SetupList;

                trigger OnAction()
                begin
                    Page.run(Page::"Data Administration");
                end;
            }
        }
    }

}