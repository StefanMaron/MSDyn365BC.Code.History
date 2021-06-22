codeunit 1655 "Office Add-In Sample Emails"
{

    trigger OnRun()
    begin
    end;

    var
        WelcomeTxt: Label 'We are all set up. Welcome to Your Business Inbox in Outlook!';
        FirstHeaderTxt: Label 'Get your business done without leaving Outlook';
        FirstParagraph_Part1Txt: Label 'With %1, your business comes to you directly in Microsoft Outlook. Getting started in Outlook or the Outlook Web App is easy. Just open the %2 add-in from an email message that a business contact sends you and work with your business data without leaving Outlook.', Comment = '%1 = Application Name(Marketing), %2 - Application Name(Full)';
        FirstParagraph_Part2Txt: Label 'Use the steps below to see how easily you can create and send documents for your business contacts.';
        GetStartedTxt: Label 'Get Started';
        OutlookHeaderTxt: Label 'In Outlook:';
        OutlookParagraphTxt: Label 'In the %1 section of the ribbon, choose Contact Insights.', Comment = '%1 = Application Name';
        OWAHeaderTxt: Label 'In the Outlook Web App:';
        OWAParagraph1Txt: Label 'Choose ''More actions'' ', Comment = 'Trailing space is required. More actions is the text used in OWA - it''s not clear how this would be translated.';
        OWAParagraph2Txt: Label ' in the upper-right corner of the email and choose %1.', Comment = '%1 = Application Name; Opening space is required.';
        SalesQuoteHdrTxt: Label 'Create a sales quote';
        SalesQuoteInst1Txt: Label 'On the app bar, choose Sales Quote from the New menu';
        SalesQuoteInst2Txt: Label 'On the lines of the quote, enter the items that Adatum Corporation wants and how many of each.';
        SalesQuoteFirstItemTxt: Label 'London Swivel Chair';
        SalesQuoteFirstItemQtyTxt: Label '7';
        SalesQuoteSecondItemTxt: Label 'Antwerp Conference Table';
        SalesQuoteSecondItemQtyTxt: Label '2';
        SalesQuoteTipTxt: Label 'Tip: You can start typing the name of the item in the Description field in the new line, or you can search for the item if you choose the lookup action.';
        SendbyEmailHdrTxt: Label 'Send the quote by email';
        SendbyEmailInst1Txt: Label 'On the document''s action menu, choose Send by Email.';
        SendbyEmailInst2Txt: Label 'This creates an email, and you should review it and the attached PDF file with the quote before you send it. For this walkthrough, you can close the email without saving it.';
        SendbyEmailInst3Txt: Label 'In the add-in pane, choose the back arrow to return to the customer dashboard.';
        FinalMessageTxt: Label 'When you are ready, return to the Getting Started guide in %1 to continue the tour.', Comment = '%1 = Application Name';
        LineNo1Txt: Label '1.';
        LineNo2Txt: Label '2.';
        LineNo3Txt: Label '3.';
        OpenParenTxt: Label '(';
        CloseParenTxt: Label ')';
        BrandingFolderTxt: Label 'ProjectMadeira/', Locked = true;

    procedure GetHTMLSampleMsg() HTMLBody: Text
    var
        ItemRec: Record Item;
        SalesLineRec: Record "Sales Line";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
    begin
        HTMLBody := '<html>' +
          '<head>' +
          '<style>' +
          '<!--' +
          ' /* Font Definitions */' +
          ' @font-face' +
          '{font-family:"Cambria Math";' +
          'panose-1:2 4 5 3 5 4 6 3 2 4;' +
          'mso-font-alt:"Calisto MT";' +
          'mso-font-charset:1;' +
          'mso-generic-font-family:roman;' +
          'mso-font-pitch:variable;' +
          'mso-font-signature:-536870145 1107305727 0 0 415 0;}' +
          '@font-face' +
          '{font-family:Calibri;' +
          'panose-1:2 15 5 2 2 2 4 3 2 4;' +
          'mso-font-alt:"Arial Rounded MT Bold";' +
          'mso-font-charset:0;' +
          'mso-generic-font-family:swiss;' +
          'mso-font-pitch:variable;' +
          'mso-font-signature:-536859905 -1073732485 9 0 511 0;}' +
          '@font-face' +
          '{font-family:"Segoe UI";' +
          'panose-1:2 11 5 2 4 2 4 2 2 3;' +
          'mso-font-alt:"Times New Roman";' +
          'mso-font-charset:0;' +
          'mso-generic-font-family:swiss;' +
          'mso-font-pitch:variable;' +
          'mso-font-signature:-469750017 -1073683329 9 0 511 0;}' +
          '@font-face' +
          '{font-family:"Segoe UI Light";' +
          'panose-1:2 11 5 2 4 2 4 2 2 3;' +
          'mso-font-charset:0;' +
          'mso-generic-font-family:swiss;' +
          'mso-font-pitch:variable;' +
          'mso-font-signature:-469750017 -1073683329 9 0 511 0;}' +
          ' /* Style Definitions */' +
          ' p.MsoNormal, li.MsoNormal, div.MsoNormal' +
          '{mso-style-unhide:no;' +
          'mso-style-qformat:yes;' +
          'mso-style-parent:"";' +
          'margin:0in;' +
          'margin-bottom:.0001pt;' +
          'mso-pagination:widow-orphan;' +
          'font-size:11.0pt;' +
          'font-family:"Calibri",sans-serif;' +
          'mso-fareast-font-family:Calibri;' +
          'mso-fareast-theme-font:minor-latin;' +
          'mso-bidi-font-family:"Times New Roman";}' +
          'a:link, span.MsoHyperlink' +
          '{mso-style-noshow:yes;' +
          'mso-style-priority:99;' +
          'color:#0563C1;' +
          'mso-themecolor:hyperlink;' +
          'text-decoration:underline;' +
          'text-underline:single;}' +
          'a:visited, span.MsoHyperlinkFollowed' +
          '{mso-style-noshow:yes;' +
          'mso-style-priority:99;' +
          'color:#954F72;' +
          'mso-themecolor:followedhyperlink;' +
          'text-decoration:underline;' +
          'text-underline:single;}' +
          'p.MsoListParagraph, li.MsoListParagraph, div.MsoListParagraph' +
          '{mso-style-priority:34;' +
          'mso-style-unhide:no;' +
          'mso-style-qformat:yes;' +
          'margin-top:0in;' +
          'margin-right:0in;' +
          'margin-bottom:0in;' +
          'margin-left:.5in;' +
          'margin-bottom:.0001pt;' +
          'mso-pagination:widow-orphan;' +
          'font-size:11.0pt;' +
          'font-family:"Calibri",sans-serif;' +
          'mso-fareast-font-family:Calibri;' +
          'mso-fareast-theme-font:minor-latin;' +
          'mso-bidi-font-family:"Times New Roman";}' +
          'span.EmailStyle17' +
          '{mso-style-type:personal-compose;' +
          'mso-style-noshow:yes;' +
          'mso-style-unhide:no;' +
          'mso-ansi-font-size:11.0pt;' +
          'mso-bidi-font-size:11.0pt;' +
          'font-family:"Calibri",sans-serif;' +
          'mso-ascii-font-family:Calibri;' +
          'mso-hansi-font-family:Calibri;' +
          'mso-bidi-font-family:"Times New Roman";' +
          'mso-bidi-theme-font:minor-bidi;' +
          'color:windowtext;}' +
          '.MsoChpDefault' +
          '{mso-style-type:export-only;' +
          'mso-default-props:yes;' +
          'font-family:"Calibri",sans-serif;' +
          'mso-ascii-font-family:Calibri;' +
          'mso-ascii-theme-font:minor-latin;' +
          'mso-fareast-font-family:Calibri;' +
          'mso-fareast-theme-font:minor-latin;' +
          'mso-hansi-font-family:Calibri;' +
          'mso-hansi-theme-font:minor-latin;' +
          'mso-bidi-font-family:"Times New Roman";' +
          'mso-bidi-theme-font:minor-bidi;}' +
          '@page WordSection1' +
          '{size:8.5in 11.0in;' +
          'margin:1.0in 1.0in 1.0in 1.0in;' +
          'mso-header-margin:.5in;' +
          'mso-footer-margin:.5in;' +
          'mso-paper-source:0;}' +
          'div.WordSection1' +
          '{page:WordSection1;}' +
          ' /* List Definitions */' +
          ' @list l0' +
          '{mso-list-id:1687175560;' +
          'mso-list-type:hybrid;' +
          'mso-list-template-ids:512502080 771374942 67698713 67698715 67698703 67698713 67698715 67698703 67698713 67698715;}' +
          '@list l0:level1' +
          '{mso-level-tab-stop:none;' +
          'mso-level-number-position:left;' +
          'margin-left:.25in;' +
          'text-indent:-.25in;' +
          'mso-ansi-font-size:9.0pt;}' +
          '@list l0:level2' +
          '{mso-level-number-format:alpha-lower;' +
          'mso-level-tab-stop:none;' +
          'mso-level-number-position:left;' +
          'margin-left:.75in;' +
          'text-indent:-.25in;}' +
          '@list l0:level3' +
          '{mso-level-number-format:roman-lower;' +
          'mso-level-tab-stop:none;' +
          'mso-level-number-position:right;' +
          'margin-left:1.25in;' +
          'text-indent:-9.0pt;}' +
          '@list l0:level4' +
          '{mso-level-tab-stop:none;' +
          'mso-level-number-position:left;' +
          'margin-left:1.75in;' +
          'text-indent:-.25in;}' +
          '@list l0:level5' +
          '{mso-level-number-format:alpha-lower;' +
          'mso-level-tab-stop:none;' +
          'mso-level-number-position:left;' +
          'margin-left:2.25in;' +
          'text-indent:-.25in;}' +
          '@list l0:level6' +
          '{mso-level-number-format:roman-lower;' +
          'mso-level-tab-stop:none;' +
          'mso-level-number-position:right;' +
          'margin-left:2.75in;' +
          'text-indent:-9.0pt;}' +
          '@list l0:level7' +
          '{mso-level-tab-stop:none;' +
          'mso-level-number-position:left;' +
          'margin-left:3.25in;' +
          'text-indent:-.25in;}' +
          '@list l0:level8' +
          '{mso-level-number-format:alpha-lower;' +
          'mso-level-tab-stop:none;' +
          'mso-level-number-position:left;' +
          'margin-left:3.75in;' +
          'text-indent:-.25in;}' +
          '@list l0:level9' +
          '{mso-level-number-format:roman-lower;' +
          'mso-level-tab-stop:none;' +
          'mso-level-number-position:right;' +
          'margin-left:4.25in;' +
          'text-indent:-9.0pt;}' +
          '@list l1' +
          '{mso-list-id:1846242723;' +
          'mso-list-type:hybrid;' +
          'mso-list-template-ids:512502080 771374942 67698713 67698715 67698703 67698713 67698715 67698703 67698713 67698715;}' +
          '@list l1:level1' +
          '{mso-level-tab-stop:none;' +
          'mso-level-number-position:left;' +
          'margin-left:.25in;' +
          'text-indent:-.25in;' +
          'mso-ansi-font-size:9.0pt;}' +
          '@list l1:level2' +
          '{mso-level-number-format:alpha-lower;' +
          'mso-level-tab-stop:none;' +
          'mso-level-number-position:left;' +
          'margin-left:.75in;' +
          'text-indent:-.25in;}' +
          '@list l1:level3' +
          '{mso-level-number-format:roman-lower;' +
          'mso-level-tab-stop:none;' +
          'mso-level-number-position:right;' +
          'margin-left:1.25in;' +
          'text-indent:-9.0pt;}' +
          '@list l1:level4' +
          '{mso-level-tab-stop:none;' +
          'mso-level-number-position:left;' +
          'margin-left:1.75in;' +
          'text-indent:-.25in;}' +
          '@list l1:level5' +
          '{mso-level-number-format:alpha-lower;' +
          'mso-level-tab-stop:none;' +
          'mso-level-number-position:left;' +
          'margin-left:2.25in;' +
          'text-indent:-.25in;}' +
          '@list l1:level6' +
          '{mso-level-number-format:roman-lower;' +
          'mso-level-tab-stop:none;' +
          'mso-level-number-position:right;' +
          'margin-left:2.75in;' +
          'text-indent:-9.0pt;}' +
          '@list l1:level7' +
          '{mso-level-tab-stop:none;' +
          'mso-level-number-position:left;' +
          'margin-left:3.25in;' +
          'text-indent:-.25in;}' +
          '@list l1:level8' +
          '{mso-level-number-format:alpha-lower;' +
          'mso-level-tab-stop:none;' +
          'mso-level-number-position:left;' +
          'margin-left:3.75in;' +
          'text-indent:-.25in;}' +
          '@list l1:level9' +
          '{mso-level-number-format:roman-lower;' +
          'mso-level-tab-stop:none;' +
          'mso-level-number-position:right;' +
          'margin-left:4.25in;' +
          'text-indent:-9.0pt;}' +
          'ol' +
          '{margin-bottom:0in;}' +
          'ul' +
          '{margin-bottom:0in;}' +
          '-->' +
          '</style>' +
          '<!--[if gte mso 10]>' +
          '<style>' +
          ' /* Style Definitions */' +
          ' table.MsoNormalTable' +
          '{mso-style-name:"Table Normal";' +
          'mso-tstyle-rowband-size:0;' +
          'mso-tstyle-colband-size:0;' +
          'mso-style-noshow:yes;' +
          'mso-style-priority:99;' +
          'mso-style-parent:"";' +
          'mso-padding-alt:0in 5.4pt 0in 5.4pt;' +
          'mso-para-margin:0in;' +
          'mso-para-margin-bottom:.0001pt;' +
          'mso-pagination:widow-orphan;' +
          'font-size:11.0pt;' +
          'font-family:"Calibri",sans-serif;' +
          'mso-ascii-font-family:Calibri;' +
          'mso-ascii-theme-font:minor-latin;' +
          'mso-hansi-font-family:Calibri;' +
          'mso-hansi-theme-font:minor-latin;' +
          'mso-bidi-font-family:"Times New Roman";' +
          'mso-bidi-theme-font:minor-bidi;}' +
          'table.MsoTableGrid' +
          '{mso-style-name:"Table Grid";' +
          'mso-tstyle-rowband-size:0;' +
          'mso-tstyle-colband-size:0;' +
          'mso-style-priority:39;' +
          'mso-style-unhide:no;' +
          'border:solid windowtext 1.0pt;' +
          'mso-border-alt:solid windowtext .5pt;' +
          'mso-padding-alt:0in 5.4pt 0in 5.4pt;' +
          'mso-border-insideh:.5pt solid windowtext;' +
          'mso-border-insidev:.5pt solid windowtext;' +
          'mso-para-margin:0in;' +
          'mso-para-margin-bottom:.0001pt;' +
          'mso-pagination:widow-orphan;' +
          'font-size:10.0pt;' +
          'font-family:"Calibri",sans-serif;' +
          'mso-ascii-font-family:Calibri;' +
          'mso-ascii-theme-font:minor-latin;' +
          'mso-hansi-font-family:Calibri;' +
          'mso-hansi-theme-font:minor-latin;}' +
          '</style>' +
          '<![endif]--><!--[if gte mso 9]><xml>' +
          ' <o:shapedefaults v:ext="edit" spidmax="1026"/>' +
          '</xml><![endif]--><!--[if gte mso 9]><xml>' +
          ' <o:shapelayout v:ext="edit">' +
          '  <o:idmap v:ext="edit" data="1"/>' +
          ' </o:shapelayout></xml><![endif]-->' +
          '</head>' +
          '<body link="#0563C1" vlink="#954F72" style=''tab-interval:.5in''>' +
          '<div class=WordSection1>' +
          '<p class=MsoNormal style=''mso-layout-grid-align:none;text-autospace:none''><span' +
          'style=''mso-bidi-font-family:Calibri;color:black''><o:p>&nbsp;</o:p></span></p>' +
          '<p class=MsoNormal><o:p>&nbsp;</o:p></p>' +
          '<div align=center>' +
          '<table class=MsoNormalTable border=0 cellspacing=0 cellpadding=0 width=625' +
          ' style=''width:468.5pt;border-collapse:collapse;mso-yfti-tbllook:1184;' +
          ' mso-padding-alt:0in 0in 0in 0in''>' +
          ' <tr style=''mso-yfti-irow:0;mso-yfti-firstrow:yes;height:64.75pt''>' +
          '  <td width=425 colspan=2 style=''width:319.1pt;background:#D9D9D9;padding:0in 0in 0in .15in;' +
          '  height:64.75pt''>' +
          '  <p class=MsoNormal><span style=''font-size:22.0pt;mso-bidi-font-size:11.0pt;' +
          '  font-family:"Segoe UI Light",sans-serif;color:#262626;mso-themecolor:text1;' +
          '  mso-themetint:217;mso-style-textfill-fill-color:#262626;mso-style-textfill-fill-themecolor:' +
          '  text1;mso-style-textfill-fill-alpha:100.0%;mso-style-textfill-fill-colortransforms:' +
          '  "lumm=85000 lumo=15000"''>' + WelcomeTxt + '</span><span style=''font-family:"Segoe UI Light",sans-serif;' +
          '  color:#262626;mso-themecolor:text1;mso-themetint:217;mso-style-textfill-fill-color:' +
          '  #262626;mso-style-textfill-fill-themecolor:text1;mso-style-textfill-fill-alpha:' +
          '  100.0%;mso-style-textfill-fill-colortransforms:"lumm=85000 lumo=15000"''><o:p></o:p></span></p>' +
          '  </td>' +
          '  <td width=199 style=''width:149.4pt;background:#D9D9D9;padding:0in 0in 0in 0in;' +
          '  height:64.75pt''>' +
          '  <p class=MsoNormal align=right style=''text-align:right''><span' +
          '  style=''color:#7F7F7F;mso-no-proof:yes''>' +
          '  </v:shape><![endif]--><![if !vml]><img width=171 height=106' +
          '  src="' + AddinManifestManagement.GetImageUrl(BrandingFolderTxt + 'WelcomeBanner.png') + '"' +
          '  alt="cid:WelcomeBanner.png@01D202D9.765B0100" v:shapes="Picture_x0020_392"><![endif]></span><span' +
          '  style=''color:#7F7F7F''><o:p></o:p></span></p>' +
          '  </td>' +
          ' </tr>' +
          ' <tr style=''mso-yfti-irow:1;height:57.0pt''>' +
          '  <td width=625 colspan=3 valign=top style=''width:468.5pt;padding:8.65pt .15in 8.65pt .15in;' +
          '  height:57.0pt''>' +
          '  <p class=MsoNormal><span style=''font-family:"Segoe UI",sans-serif;color:#0070C0''>' +
          FirstHeaderTxt + '</span><span style=''font-size:9.0pt;' +
          '  font-family:"Segoe UI",sans-serif;color:#00B0F0''><o:p></o:p></span></p>' +
          '  <p class=MsoNormal><span style=''font-size:10.0pt;font-family:"Segoe UI",sans-serif;' +
          '  color:#595959''>' + StrSubstNo(FirstParagraph_Part1Txt, PRODUCTNAME.Marketing, PRODUCTNAME.Full) + '<o:p></o:p></span></p>' +
          '  <p class=MsoNormal><span style=''font-size:10.0pt;font-family:"Segoe UI",sans-serif;' +
          '  color:#595959''><o:p>&nbsp;</o:p></span></p>' +
          '  <p class=MsoNormal><span style=''font-size:10.0pt;mso-bidi-font-size:11.0pt;' +
          '  font-family:"Segoe UI",sans-serif;color:#595959''>' + FirstParagraph_Part2Txt + '</span><span' +
          '  style=''font-size:9.0pt;font-family:"Segoe UI",sans-serif;color:#595959''><o:p></o:p></span></p>' +
          '  </td>' +
          ' </tr>' +
          ' <tr style=''mso-yfti-irow:2;height:13.0pt''>' +
          '  <td width=625 colspan=3 valign=top style=''width:468.5pt;padding:.05in .15in .05in .15in;' +
          '  height:13.0pt''>' +
          '  <p class=MsoNormal><span style=''font-family:"Segoe UI",sans-serif;color:#0070C0''>' + GetStartedTxt + '<o:p></o:p></span></p>' +
          '  </td>' +
          ' </tr>' +
          ' <tr style=''mso-yfti-irow:3;height:84.0pt''>' +
          '  <td width=311 valign=top style=''width:233.6pt;padding:0in .2in 8.65pt .15in;' +
          '  height:84.0pt''>' +
          '  <p class=MsoNormal><span style=''font-size:10.0pt;font-family:"Segoe UI",sans-serif;' +
          '  color:#0070C0''>' + OutlookHeaderTxt + '</span></p>' +
          '  <p class=MsoNormal><span style=''font-size:10.0pt;font-family:"Segoe UI",sans-serif;' +
          '  color:#595959''>' + StrSubstNo(OutlookParagraphTxt, PRODUCTNAME.Short) + '<o:p></o:p></span></p>' +
          '  <p class=MsoListParagraph style=''margin-left:.25in''><span style=''font-size:' +
          '  10.0pt;font-family:"Segoe UI",sans-serif;color:#595959''><o:p>&nbsp;</o:p></span></p>' +
          '  <p class=MsoNormal align=center style=''text-align:center''><span' +
          '  style=''font-size:10.0pt;font-family:"Segoe UI",sans-serif;color:#595959;' +
          '  mso-no-proof:yes''>' +
          '  </v:shape><![endif]--><![if !vml]><img width=49 height=51' +
          '  src="' + AddinManifestManagement.GetImageUrl(BrandingFolderTxt + 'OutlookIcon.png') + '"' +
          '  alt="cid:OutlookIcon.png@01D1FFAB.2B39E500" v:shapes="Picture_x0020_5"><![endif]></span><span' +
          '  style=''font-size:10.0pt;font-family:"Segoe UI",sans-serif;color:#595959''><o:p></o:p></span></p>' +
          '  </td>' +
          '  <td width=313 colspan=2 valign=top style=''width:234.9pt;padding:0in .2in 0in 5.75pt;' +
          '  height:84.0pt''>' +
          '  <p class=MsoListParagraph style=''margin-left:.25in''><span style=''font-size:' +
          '  10.0pt;font-family:"Segoe UI",sans-serif;color:#0070C0''>' + OWAHeaderTxt + '</span></p>' +
          '  <p class=MsoListParagraph style=''margin-left:.25in''><span style=''font-size:' +
          '  10.0pt;font-family:"Segoe UI",sans-serif;color:#595959''>' + OWAParagraph1Txt + OpenParenTxt +
          '  <span style=''mso-no-proof:yes''></v:shape><![endif]--><![if !vml]><img width=21 height=14' +
          '  src="' + AddinManifestManagement.GetImageUrl(BrandingFolderTxt + 'OutlookEllipse.png') + '"' +
          '  alt="cid:OutlookEllipse.png@01D1838A.7FBEA0E0" v:shapes="Picture_x0020_1058"><![endif]></span><span' +
          '  style=''mso-spacerun:yes''> </span>' + CloseParenTxt + StrSubstNo(OWAParagraph2Txt, PRODUCTNAME.Short) + '</span><span' +
          '  style=''font-size:10.0pt;font-family:"Segoe UI",sans-serif''> <o:p></o:p></span></p>' +
          '  <p class=MsoListParagraph style=''margin-left:.25in''><span style=''font-size:' +
          '  10.0pt;font-family:"Segoe UI",sans-serif''><o:p>&nbsp;</o:p></span></p>' +
          '  <p class=MsoNormal align=center style=''text-align:center''><span' +
          '  style=''font-size:10.0pt;font-family:"Segoe UI",sans-serif;mso-no-proof:yes''>' +
          '  </v:shape><![endif]--><![if !vml]><img width=196 height=50' +
          '  src="' + AddinManifestManagement.GetImageUrl(BrandingFolderTxt + 'OutlookOWA.png') + '"' +
          '  alt="cid:OutlookOWA.png@01D1709E.B113E5F0" v:shapes="Picture_x0020_20"><![endif]></span><span' +
          '  style=''font-size:10.0pt;font-family:"Segoe UI",sans-serif;color:#595959''><o:p></o:p></span></p>' +
          '  </td>' +
          ' </tr>' +
          ' <tr style=''mso-yfti-irow:4;height:186.75pt''>' +
          '  <td width=625 colspan=3 valign=top style=''width:468.5pt;padding:0in .25in 8.65pt .15in;' +
          '  height:186.75pt''>' +
          '  <p class=MsoNormal><span style=''font-family:"Segoe UI",sans-serif;color:#0070C0''>' + SalesQuoteHdrTxt + '<o:p></o:p></span></p>' +
          '  <p class=MsoListParagraph style=''margin-left:.25in;text-indent:-.25in;' +
          '  mso-list:l1 level1 lfo1''><![if !supportLists]><span style=''font-size:9.0pt;' +
          '  mso-bidi-font-size:10.0pt;font-family:"Segoe UI",sans-serif;mso-fareast-font-family:' +
          '  "Segoe UI";color:#595959''><span style=''mso-list:Ignore''>' + LineNo1Txt + '<span' +
          '  style=''font:7.0pt "Times New Roman"''>&nbsp;&nbsp;&nbsp;&nbsp; </span></span></span><![endif]><span' +
          '  style=''font-size:10.0pt;font-family:"Segoe UI",sans-serif;color:#595959''>' + SalesQuoteInst1Txt + ' ' + OpenParenTxt + '<span' +
          '  style=''mso-no-proof:yes''>' +
          '  </v:shape><![endif]--><![if !vml]><img width=13 height=16' +
          '  src="' + AddinManifestManagement.GetImageUrl(BrandingFolderTxt + 'OutlookNewDocument.png') + '"' +
          '  alt="cid:OutlookNewDocument.png@01D18389.2E215670" v:shapes="Picture_x0020_1057"><![endif]></span><span' +
          '  style=''mso-spacerun:yes''> </span>' + CloseParenTxt + '<o:p></o:p></span></p>' +
          '  <p class=MsoListParagraph style=''margin-left:.25in;text-indent:-.25in;' +
          '  mso-list:l1 level1 lfo1''><![if !supportLists]><span style=''font-size:9.0pt;' +
          '  font-family:"Segoe UI",sans-serif;mso-fareast-font-family:"Segoe UI";' +
          '  color:#595959''><span style=''mso-list:Ignore''>' + LineNo2Txt + '<span style=''font:7.0pt "Times New Roman"''>&nbsp;&nbsp;&nbsp;&nbsp;' +
          '  </span></span></span><![endif]><span style=''font-size:10.0pt;mso-bidi-font-size:' +
          '  9.0pt;font-family:"Segoe UI",sans-serif;color:#595959''>' + SalesQuoteInst2Txt + '<o:p></o:p></span></p>' +
          '  <p class=MsoListParagraph style=''margin-left:.25in''><span style=''font-size:' +
          '  10.0pt;mso-bidi-font-size:9.0pt;font-family:"Segoe UI",sans-serif;color:#595959''><o:p>&nbsp;</o:p></span></p>' +
          '  <table class=MsoTableGrid border=0 cellspacing=0 cellpadding=0' +
          '   style=''margin-left:.5in;border-collapse:collapse;border:none;mso-yfti-tbllook:' +
          '   1184;mso-padding-alt:0in 5.4pt 0in 5.4pt;mso-border-insideh:none;mso-border-insidev:' +
          '   none''>' +
          '   <tr style=''mso-yfti-irow:0;mso-yfti-firstrow:yes''>' +
          '    <td width=177 valign=top style=''width:133.1pt;border:none;border-bottom:' +
          '    solid #595959 1.0pt;mso-border-bottom-alt:solid #595959 .5pt;padding:0in 5.4pt 0in 5.4pt''>' +
          '    <p class=MsoListParagraph style=''margin-left:0in''><span style=''font-size:' +
          '    10.0pt;mso-bidi-font-size:9.0pt;font-family:"Segoe UI",sans-serif;' +
          '    color:#595959''>' + ItemRec.TableCaption + '<o:p></o:p></span></p>' +
          '    </td>' +
          '    <td width=79 valign=top style=''width:58.9pt;border:none;border-bottom:solid #595959 1.0pt;' +
          '    mso-border-bottom-alt:solid #595959 .5pt;padding:0in 5.4pt 0in 5.4pt''>' +
          '    <p class=MsoListParagraph align=center style=''margin-left:0in;text-align:' +
          '    center''><span style=''font-size:10.0pt;mso-bidi-font-size:9.0pt;font-family:' +
          '    "Segoe UI",sans-serif;color:#595959''>' + SalesLineRec.FieldCaption(Quantity) + '<o:p></o:p></span></p>' +
          '    </td>' +
          '   </tr>' +
          '   <tr style=''mso-yfti-irow:1''>' +
          '    <td width=177 valign=top style=''width:133.1pt;border:none;mso-border-top-alt:' +
          '    solid #595959 .5pt;padding:0in 5.4pt 0in 5.4pt''>' +
          '    <p class=MsoListParagraph style=''margin-left:0in''><span style=''font-size:' +
          '    10.0pt;mso-bidi-font-size:9.0pt;font-family:"Segoe UI",sans-serif;' +
          '    color:#595959''>' + SalesQuoteFirstItemTxt + '<o:p></o:p></span></p>' +
          '    </td>' +
          '    <td width=79 valign=top style=''width:58.9pt;border:none;mso-border-top-alt:' +
          '    solid #595959 .5pt;padding:0in 5.4pt 0in 5.4pt''>' +
          '    <p class=MsoListParagraph align=center style=''margin-left:0in;text-align:' +
          '    center''><span style=''font-size:10.0pt;mso-bidi-font-size:9.0pt;font-family:' +
          '    "Segoe UI",sans-serif;color:#595959''>' + SalesQuoteFirstItemQtyTxt + '<o:p></o:p></span></p>' +
          '    </td>' +
          '   </tr>' +
          '   <tr style=''mso-yfti-irow:2;mso-yfti-lastrow:yes''>' +
          '    <td width=177 valign=top style=''width:133.1pt;padding:0in 5.4pt 0in 5.4pt''>' +
          '    <p class=MsoListParagraph style=''margin-left:0in''><span style=''font-size:' +
          '    10.0pt;mso-bidi-font-size:9.0pt;font-family:"Segoe UI",sans-serif;' +
          '    color:#595959''>' + SalesQuoteSecondItemTxt + '<o:p></o:p></span></p>' +
          '    </td>' +
          '    <td width=79 valign=top style=''width:58.9pt;padding:0in 5.4pt 0in 5.4pt''>' +
          '    <p class=MsoListParagraph align=center style=''margin-left:0in;text-align:' +
          '    center''><span style=''font-size:10.0pt;mso-bidi-font-size:9.0pt;font-family:' +
          '    "Segoe UI",sans-serif;color:#595959''>' + SalesQuoteSecondItemQtyTxt + '<o:p></o:p></span></p>' +
          '    </td>' +
          '   </tr>' +
          '  </table>' +
          '  <p class=MsoListParagraph style=''margin-left:.25in''><span style=''font-size:' +
          '  10.0pt;mso-bidi-font-size:9.0pt;font-family:"Segoe UI",sans-serif;color:#595959''><o:p>&nbsp;</o:p></span></p>' +
          '  <p class=MsoListParagraph style=''margin-top:0in;margin-right:0in;margin-bottom:' +
          '  6.0pt;margin-left:.25in''><span style=''font-size:10.0pt;mso-bidi-font-size:' +
          '  9.0pt;font-family:"Segoe UI",sans-serif;color:#595959''>' + SalesQuoteTipTxt + '.<o:p></o:p></span></p>' +
          '  <p class=MsoNormal style=''margin-bottom:6.0pt''><span style=''font-size:10.0pt;' +
          '  mso-bidi-font-size:9.0pt;font-family:"Segoe UI",sans-serif;color:#595959''><o:p>&nbsp;</o:p></span></p>' +
          '  <p class=MsoNormal><span style=''font-family:"Segoe UI",sans-serif;color:#0070C0''>' + SendbyEmailHdrTxt + '<o:p></o:p></span></p>' +
          '  <p class=MsoListParagraph style=''margin-left:.25in;text-indent:-.25in;' +
          '  mso-list:l0 level1 lfo2''><![if !supportLists]><span style=''font-size:9.0pt;' +
          '  font-family:"Segoe UI",sans-serif;mso-fareast-font-family:"Segoe UI";' +
          '  color:#595959''><span style=''mso-list:Ignore''>' + LineNo1Txt + '<span style=''font:7.0pt "Times New Roman"''>&nbsp;&nbsp;&nbsp;&nbsp;' +
          '  </span></span></span><![endif]><span style=''font-size:10.0pt;mso-bidi-font-size:' +
          '  9.0pt;font-family:"Segoe UI",sans-serif;color:#595959''>' + SendbyEmailInst1Txt + ' ' + OpenParenTxt + '<span style=''mso-no-proof:yes''>' +
          '  </v:shape><![endif]--><![if !vml]><img width=21 height=14' +
          '  src="' + AddinManifestManagement.GetImageUrl(BrandingFolderTxt + 'OutlookEllipse.png') + '"' +
          '  alt="cid:OutlookEllipse.png@01D1838A.7FBEA0E0" v:shapes="Picture_x0020_1058"><![endif]></span><span' +
          '  style=''mso-spacerun:yes''> </span>' + CloseParenTxt + '<o:p></o:p></span></p>' +
          '  <p class=MsoListParagraph style=''margin-left:.25in;text-indent:-.25in;' +
          '  mso-list:l0 level1 lfo2''><![if !supportLists]><span style=''font-size:9.0pt;' +
          '  font-family:"Segoe UI",sans-serif;mso-fareast-font-family:"Segoe UI";' +
          '  color:#595959''><span style=''mso-list:Ignore''>' + LineNo2Txt + '<span style=''font:7.0pt "Times New Roman"''>&nbsp;&nbsp;&nbsp;&nbsp;' +
          '  </span></span></span><![endif]><span style=''font-size:10.0pt;mso-bidi-font-size:' +
          '  9.0pt;font-family:"Segoe UI",sans-serif;color:#595959''>' + SendbyEmailInst2Txt + '<o:p></o:p></span></p>' +
          '  <p class=MsoListParagraph style=''margin-left:.25in;text-indent:-.25in;' +
          '  mso-list:l0 level1 lfo2''><![if !supportLists]><span style=''font-size:9.0pt;' +
          '  mso-bidi-font-size:11.0pt;font-family:"Segoe UI",sans-serif;mso-fareast-font-family:' +
          '  "Segoe UI";color:#595959''><span style=''mso-list:Ignore''>' + LineNo3Txt + '<span' +
          '  style=''font:7.0pt "Times New Roman"''>&nbsp;&nbsp;&nbsp;&nbsp; </span></span></span><![endif]><span' +
          '  style=''font-size:10.0pt;mso-bidi-font-size:9.0pt;font-family:"Segoe UI",sans-serif;' +
          '  color:#595959''>' + SendbyEmailInst3Txt + '</span><span style=''font-family:"Segoe UI",sans-serif;' +
          '  color:#595959''><o:p></o:p></span></p>' +
          '  <p class=MsoListParagraph style=''margin-left:.25in''><span style=''font-family:' +
          '  "Segoe UI",sans-serif;color:#595959''><o:p>&nbsp;</o:p></span></p>' +
          '  <p class=MsoNormal><span style=''font-size:10.0pt;font-family:"Segoe UI",sans-serif;' +
          '  color:#595959''>' + StrSubstNo(FinalMessageTxt, PRODUCTNAME.Marketing) + '</span><span style=''font-size:9.0pt;' +
          '  mso-bidi-font-size:10.0pt;font-family:"Segoe UI",sans-serif;color:#595959''><o:p></o:p></span></p>' +
          '  </td>' +
          ' </tr>' +
          ' <tr style=''mso-yfti-irow:5;height:.2in''>' +
          '  <td width=625 colspan=3 valign=top style=''width:468.5pt;background:#00B0F0;' +
          '  padding:0in 5.4pt 0in 5.4pt;height:.2in''>' +
          '  <p class=MsoNormal><o:p>&nbsp;</o:p></p>' +
          '  </td>' +
          ' </tr>' +
          ' <tr style=''mso-yfti-irow:6;mso-yfti-lastrow:yes;height:.2in''>' +
          '  <td width=625 colspan=3 valign=top style=''width:468.5pt;padding:0in 5.4pt 0in 5.4pt;' +
          '  height:.2in''>' +
          '  <p class=MsoNormal><span style=''mso-no-proof:yes''><![if !vml]><img width=150 height=55' +
          '  src="' + AddinManifestManagement.GetImageUrl(BrandingFolderTxt + 'MS_Logo.png') + '"' +
          '  v:shapes="Picture_x0020_8"><![endif]></span><o:p></o:p></p>' +
          '  </td>' +
          ' </tr>' +
          ' <![if !supportMisalignedColumns]>' +
          ' <tr height=0>' +
          '  <td width=311 style=''border:none''></td>' +
          '  <td width=114 style=''border:none''></td>' +
          '  <td width=199 style=''border:none''></td>' +
          ' </tr>' +
          ' <![endif]>' +
          '</table>' +
          '</div>' +
          '<p class=MsoNormal><span style=''mso-bidi-font-family:"Times New Roman";' +
          'mso-bidi-theme-font:minor-bidi''><o:p>&nbsp;</o:p></span></p>' +
          '</div>' +
          '</body>' +
          '</html>'
    end;
}

