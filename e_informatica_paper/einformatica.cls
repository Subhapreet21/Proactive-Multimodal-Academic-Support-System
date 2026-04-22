%
% e-Informatyka.pl TeX styles definitions to be used by the following journals:
% 1) e-Informatica Software Engineering Journal (ISEJ)
% 2) Scientific Papers of the Institute of Applied Informatics of Wroclaw University of Science and Technology or SPSE (Scientific Papers on Software Engineering) for short.
% Michał Stochmiałek misto@e-informatyka.pl
% Lech Madeyski lma@e-informatyka.pl
% Piotr Przybyl ppr@e-informatyka.pl
% (C) 2005-2007 e-Informatyka.pl
% Wojciech Myszka wojciech.myszka@pwr.wroc.pl
% (C) 2005-2024 e-informatyka.pl

\ProvidesClass{einformatica}[2024/11/05]
\NeedsTeXFormat{LaTeX2e}
%
%
\newif\if@eb
\@ebfalse
\DeclareOption{eb}
{\@ebtrue}
%
\newif\if@print
\@printfalse
\DeclareOption{print}
{\@printtrue\@efinalfalse}
\newif\if@efinal
\@efinaltrue
\DeclareOption{efinal} %
{\@efinaltrue}

\PassOptionsToClass{11pt}{mwart}
\PassOptionsToClass{twoside}{mwart}
\PassOptionsToClass{noindentfirst,a4paper}{mwart}
\ProcessOptions
\LoadClass{mwart}
\if@print
 \RequirePackage[width=150mm,height=25cm,twoside,includeheadfoot,left=35mm,heightrounded=true]{geometry}
\else
%
 \RequirePackage[width=150mm,height=25cm,twoside,includeheadfoot,left=35mm,heightrounded=true]{geometry}
\fi
\setlength\columnsep{5mm}
\topsep0pt
\RequirePackage[bottom]{footmisc}
\RequirePackage{ifthen}
\RequirePackage{etoolbox}
\RequirePackage{fancyhdr}
\RequirePackage[verbose=true]{microtype}
\RequirePackage[all]{nowidow}
\RequirePackage{amsmath}
\RequirePackage{xcolor}
\allowdisplaybreaks[4]
\RequirePackage{lastpage}
\if@eb
\RequirePackage{draftwatermark}
\wlog{!!! draft}
\SetWatermarkAngle{0}
\SetWatermarkFontSize{8pt}
\SetWatermarkLightness{0.4}
\DraftwatermarkOptions{vpos=0.03\paperheight}
\DraftwatermarkOptions{text={\textsf{\begin{tabular}{c}This article has been accepted for publication in e-Informatica Software Engineering Journal (EISEJ).\\  This is the author's version wich has not been fully edited and content may change prior to final publication.\\ Citation information: DOI \@edoi\end{tabular}}}}
\DraftwatermarkOptions{stamp=true}
\else\fi
\RequirePackage[noadjust]{cite} %
\RequirePackage{silence}
\WarningsOff[caption]
\RequirePackage[hyphens]{url}
\urlstyle{rm}
\RequirePackage{stringstrings}
\RequirePackage{environ}
\RequirePackage{lmodern}
\RequirePackage{hyphenat}
\RequirePackage{microtype}
\IfFileExists{redakcja}{%
 \RequirePackage{newfile}
 \newoutputstream{bibs}
 \newoutputstream{meta}
 \newoutputstream{doi}
 \openoutputfile{\jobname.bbb}{bibs}
 \openoutputfile{meta.tex}{meta}
 \openoutputfile{\jobname.md}{doi}
}{}
%

\RequirePackage[pdfa, unicode, breaklinks, hyperindex, hyperfootnotes, hyperfigures, plainpages=false, pdfpagelabels, pdfstartview=Fit, pdfdisplaydoctitle, pdfborder={0 0 0}, pdfborderstyle={/S/U/W 0}, pdfusetitle]{hyperref}

%
\frenchspacing

%
%
\renewcommand\normalsize{%
 \@setfontsize\normalsize\@xipt{13.6}%
 %
 %
 \abovedisplayskip .3\baselineskip
 \abovedisplayshortskip .3\baselineskip
 %
 %
 \belowdisplayshortskip .3\baselineskip
 \belowdisplayskip .3\baselineskip
}

%
\newbool{@firstbib}
\global\booltrue{@firstbib}

%
\SetSectionFormatting{section}
{2\baselineskip plus 5pt minus 2pt}
{\FormatHangHeading{\large}}
{1\baselineskip plus 3pt}
\SetSectionFormatting{subsection}
{1.33\baselineskip plus 3pt minus 1pt}
{\FormatHangHeading{}}
{0.67\baselineskip plus 2pt}
\SetSectionFormatting{subsubsection}
{1\baselineskip plus 2pt minus 1pt}
{\FormatHangHeading{\normalfont}}
{1\baselineskip plus 2pt minus 1pt}
\SetSectionFormatting[runin]{paragraph}
{\smallskipamount}
{\FormatRunInHeading{}}
{.5em}
\SetSectionFormatting[runin]{subparagraph}
{0pt}
{\FormatRunInHeading{}}
{.3em}
%
%
\setlength\floatsep    {12\p@ \@plus 2\p@ \@minus 2\p@}
\setlength\textfloatsep{7pt plus 3pt}
\setlength\intextsep   {12\p@ \@plus 2\p@ \@minus 2\p@}
\setlength\dblfloatsep    {12\p@ \@plus 2\p@ \@minus 2\p@}
\setlength\dbltextfloatsep{20\p@ \@plus 2\p@ \@minus 4\p@}
\setlength\@fptop{0\p@}%
\setlength\@fpsep{8\p@} %
\setlength\@fpbot{0\p@ \@plus 1fil}
\setlength\@dblfptop{0\p@}%
\setlength\@dblfpsep{8\p@}%
\setlength\@dblfpbot{0\p@ \@plus 1fil}
%
\setlength{\medskipamount}{.5\baselineskip}
%
\setlength\abovecaptionskip{.5\baselineskip}
\setlength\belowcaptionskip{.5\baselineskip} %
%
\setcounter{topnumber}{3}
\renewcommand\topfraction{.85}
\setcounter{bottomnumber}{2}
\renewcommand\bottomfraction{.7}
\setcounter{totalnumber}{3}
\renewcommand\textfraction{.2}
\renewcommand\floatpagefraction{.5}
\setcounter{dbltopnumber}{2}
\renewcommand\dbltopfraction{.7}
\renewcommand\dblfloatpagefraction{.5}
%

%
\newcommand\captionof[1]{\def\@captype{#1}\secondarysize\caption}
%
\renewcommand\labelitemi{\textendash}
\renewcommand\labelitemii{\textendash}
\renewcommand\labelitemiii{\textendash}
%
%
\renewenvironment{quote}%
{\list{}{\partopsep\topsep \topsep\z@\leftmargin\parindent\rightmargin 0pt}%
 \item\relax}%
{\endlist}
%

%
\def\@opargbegintheorem#1#2#3{\trivlist\item[\hskip \labelsep{\bfseries #1\ #2\ (#3).}]\itshape}

%
\renewenvironment{thebibliography}[1]%
{
 \ifbool{@firstbib}{%
  \print@credits%
  \print@eCI%
  \print@Data%
  \print@funding%
  \print@ai%
  \global\boolfalse{@firstbib}}{}
 \subsection*{\refname}%
 \@mkboth{\MakeUppercase\refname}{\MakeUppercase\refname}%
 \small\list{\@biblabel{\@arabic\c@enumiv}}%
 {\settowidth\labelwidth{\@biblabel{#1}}%
  \leftmargin\labelwidth\advance\leftmargin\labelsep\@openbib@code%
  \usecounter{enumiv}%
  \let\p@enumiv\@empty%
  \renewcommand\theenumiv{\@arabic\c@enumiv}}%
 \sloppy\clubpenalty4000\@clubpenalty \clubpenalty%
 \widowpenalty4000%
 \sfcode`\.\@m
}
{\def\@noitemerr
 {\@latex@warning{Empty `thebibliography' environment}}%
 \endlist}

\def\fnum@figure{\centering\small\figurename\nobreakspace\thefigure}
\def\fnum@table{\centering\small\tablename\nobreakspace\thetable}

\renewcommand\footnoterule{%
 \kern-3\p@
 \vspace{0.5em}
 \hrule\@width.4\columnwidth
 \kern2.6\p@}

%

%
\def\issue#1{\xdef\@issue{#1}}
\def\volume#1{\xdef\@volume{#1}}
\def\eIyear#1{\xdef\@eIyear{#1}}
\IfFileExists{einfo.cfg}{\input{einfo.cfg}}{\issue{0}\volume{00}\eIyear{0000}}
%
%
\def\eIsubmitted#1{\xdef\@eIsubmitted{#1}}
\def\eIrevised#1{\xdef\@eIrevised{#1}}
\def\eIaccepted#1{\xdef\@eIaccepted{#1}}
\def\eIpublished#1{\xdef\@eIpublished{#1}}
%
%
%
\eIsubmitted{}
\eIrevised{}
\eIaccepted{}
\eIpublished{}
%
%
%
\def\doi#1{\xdef\@edoi{#1}}
%
%
\def\@strona{https://www.e-informatyka.pl/EISEJ/papers/\@eIyear/\@issue/\@enumber/}
\def\@estronabib{https://www.e-informatyka.pl/wp-content/plugins/wp-publications/\jobname.bib}

%
%
\fancypagestyle{copyright}{%
 \fancyhf{}%
 \fancyheadoffset[L]{15mm}
 \fancyfootoffset[R]{15mm}
 \fancyhead[R]{}%
 \fancyfoot[C]{}
 \fancyfoot[R]{\raisebox{9.5mm}[0pt][0pt]{\large\thepage}}
 \fancyhead[L]{\setlength{\unitlength}{1mm}
  \begin{picture}(0,0)\small
   %
   \put(0,-15){\includegraphics[width=13.5mm]{EISEJ_logo.png}}
   \put(17,-2){\textsf{\href{https://www.e-informatyka.pl/}{\textbf{e-Informatica Software Engineering Journal}}}}
   \put(17,-8){\textsf{Volume \href{https://www.e-informatyka.pl/index.php/einformatica/volumes/volume-2026/}{\@volume}, Issue \@issue, pages: \arabic{aaa}--\arabic{aab}}}
   \put(17,-14){\textsf{\ifx\@edoi\undefined\else DOI:\space\href{\ifx\@strona\undefined https://dx.doi.org/\@edoi\else\@strona\fi}{\@edoi}\fi}}
   \put(0,-19){\textcolor[HTML]{706152}{\rule{\dimeval{\textwidth+14mm}}{1.3mm}}}
  \end{picture}
 }
 \fancyhead[R]{\setlength{\unitlength}{1mm}
  \begin{picture}(0,0)\small
   \if@print\else
    \put(2,-15){\makebox[0mm][r]{\href{\@estronabib}{\textsc{Bib}\TeX}}}\fi
  \end{picture}
 }
 %
 %
%
 \fancyfoot[L]{\scriptsize\textcopyright\ \@eIyear\ The Authors. Published by Wrocław University of Science and Technology Publishing House.\\ This is an open access article under the \href{http://creativecommons.org/licenses/by/4.0/}{CC BY-SA 4.0 license international.}}
 %
 \renewcommand{\headrulewidth}{0pt}%
 \renewcommand{\footrulewidth}{0.4pt}%
 %
 %
 %
 %
 %
}

%
%

\thispagestyle{copyright}
\fancypagestyle{article}{%
 \fancyhf{}%
 %
 %
 \fancyfootoffset[RO]{15mm}
 \fancyfootoffset[LE]{15mm}
 \fancyhead[R]{\footnotesize \href{\@strona}{e-Informatica Software Engineering Journal, \@volume\ (\@eIyear)}, \ifx\@edoi\undefined\else\substring[v]{\@edoi}{15}{$}\fi}
 %
 \fancyhead[L]{\footnotesize\ifx\@eshortauthorshead\undefined\@eauthorshead\else\@eshortauthorshead\fi}
 %
%
  %
  \fancyfoot[RO]{\raisebox{9.5mm}[0pt][0pt]{\large\thepage}}
  %
  \fancyfoot[LE]{\raisebox{9.5mm}[0pt][0pt]{\large\thepage}}
%
%
%
%
%
%
 \renewcommand{\footrulewidth}{.4pt}
 %
 %
 %
}
\pagestyle{article}

\newcommand{\titlesize}{%
 \@setfontsize\titlesize{19}{23}}

\def\title#1{\lineskip 0.75em\xdef\@etitle{#1}}
%
\def\subtitle#1{\xdef\@esubtitle{#1}}
%
\def\shorttitle#1{\xdef\@eshorttitle{#1}}
\def\shortauthorshead#1{\xdef\@eshortauthorshead{#1}}
%
\def\@stdkeyset{preparation, article, template, LaTeX, e-Informatica}
\def\keywordset#1{\xdef\@ekeywordset{#1}}
%
\def\NA{NA}
\def\Funding#1{\xdef\@efunding{#1}}
\newcommand{\print@funding}{%
 \ifx\@efunding\undefined
  \section*{Funding}
  \textcolor{red}{This research did not receive any specific grant from funding agencies in the public, commercial, or not-for-profit sector}%
  %
 \else\ifx\@efunding\NA\else
  \section*{Funding}
  \@efunding\par
 \fi\fi
}
\def\Credits#1{\xdef\@ecredits{#1}}
\newcommand{\print@credits}{%
 \ifx\@ecredits\undefined
  \section*{CRediT authorship contribution statement\protect\footnote{https://credit.niso.org/}}
  \textcolor{red}{[\emph{Specify the First- and the Last-Name of the first Author}]: Data curation, Methodology, Investigation, Writing – original draft, Writing – review and editing, Visualization.\\{} [\emph{Specify the First- and the Last-Name of the second Author}]: Conceptualization, Funding acquisition, Methodology, Investigation, Writing – review and editing, Supervision…}
 \else\ifx\@ecredits\NA\else
  \section*{CRediT authorship contribution statement}
  \@ecredits\par
 \fi\fi
}
\def\CompetingInterests#1{\xdef\@eCI{#1}}
\newcommand{\print@eCI}{%
 \ifx\@eCI\undefined
  \section*{Declaration of competing interest}
  \textcolor{red}{The authors declare that they have no known competing financial interests or personal relationships that could have appeared to influence the work reported in this paper.}
 \else\ifx\@eCI\NA\else%
  \section*{Declaration of competing interest}
  \@eCI\par
 \fi\fi
}
\def\Data#1{\xdef\@eData{#1}}
\def\DataLink#1{\xdef\@DataLink{#1}}
\newcommand{\print@Data}{%
 \ifx\@eData\undefined
  \section*{Data and code availability}
  \textcolor{red}{We have shared our data and code in a reproduction package available at \url{https://zenodo.org/record/XXXXXXX}.}
 \else%
  \ifx\@eData\NA%
   %
   %
  \else
   \section*{Data and code availability}
   \@eData\par
  \fi
 \fi
}
\def\AIDeclaration#1{\xdef\@eai{#1}}
\newcommand{\print@ai}{%
 \ifx\@eai\undefined
  \section*{Declaration of AI assistance in the writing process}
  \textcolor{red}{During the preparation of this work, the author(s) utilised [\emph{Specify Tool/Service Name}] in order to [\emph{State the Reason for Use, e.g., improve grammar and clarity}]. Subsequent to the application of this tool/service, the author(s) reviewed and edited the content as necessary and accept full responsibility for the final content of the publication.}
 \else%
  \ifx\@eai\NA%
   %
   %
  \else
   \section*{Declaration of AI assistance in the writing process}
   \@eai\par
  \fi
 \fi
}
%
%
%
%
%
\def\thanks#1{\xdef\@ethanks{#1}}

%
%
%
%
%
%
%

%
\newcommand{\EIauthorI}[6]{\def\afIname{#1}\def\alIname{#2}\def\aIaffil{#3}\def\aIemail{#4}\def\aIorcid{#5}\def\aIcorr{#6}}
\newcommand{\EIauthorII}[6]{\def\afIIname{#1}\def\alIIname{#2}\def\aIIaffil{#3}\def\aIIemail{#4}\def\aIIorcid{#5}\def\aIIcorr{#6}}
\newcommand{\EIauthorIII}[6]{\def\afIIIname{#1}\def\alIIIname{#2}\def\aIIIaffil{#3}\def\aIIIemail{#4}\def\aIIIorcid{#5}\def\aIIIcorr{#6}}
\newcommand{\EIauthorIV}[6]{\def\afIVname{#1}\def\alIVname{#2}\def\aIVaffil{#3}\def\aIVemail{#4}\def\aIVorcid{#5}\def\aIVcorr{#6}}
\newcommand{\EIauthorV}[6]{\def\afVname{#1}\def\alVname{#2}\def\aVaffil{#3}\def\aVemail{#4}\def\aVorcid{#5}\def\aVcorr{#6}}
\newcommand{\EIauthorVI}[6]{\def\afVIname{#1}\def\alVIname{#2}\def\aVIaffil{#3}\def\aVIemail{#4}\def\aVIorcid{#5}\def\aVIcorr{#6}}
\newcommand{\EIauthorVII}[6]{\def\afVIIname{#1}\def\alVIIname{#2}\def\aVIIaffil{#3}\def\aVIIemail{#4}\def\aVIIorcid{#5}\def\aVIIcorr{#6}}
\newcommand{\EIauthorVIII}[6]{\def\afVIIIname{#1}\def\alVIIIname{#2}\def\aVIIIaffil{#3}\def\aVIIIemail{#4}\def\aVIIIorcid{#5}\def\aVIIIcorr{#6}}
\newcommand{\EIauthorIX}[6]{\def\afIXname{#1}\def\alIXname{#2}\def\aIXaffil{#3}\def\aIXemail{#4}\def\aIXorcid{#5}\def\aIXcorr{#6}}
\newcommand{\EIauthorX}[6]{\def\afXname{#1}\def\alXname{#2}\def\aXaffil{#3}\def\aXemail{#4}\def\aXorcid{#5}\def\aXcorr{#6}}
%
\def\@eicorresponding{}
\newcounter{@einumcorr}
%

%
%
\newcommand{\orcid}[1]{%
 \if@print%
 \else%
  \href{https://orcid.org/#1}{\includegraphics[width=10pt]{ORCID.pdf}}%
 \fi%
}
\newcommand{\mailto}[1]{%
 \href{mailto:#1}{\texttt{#1}}%
}

\def\@storeabstract#1{\gdef\@eabstract{#1}}
\renewenvironment{abstract}[1][-]{\collect@body\@storeabstract}{}

\def\@storeepigraph#1{\gdef\@eepigraph{#1}}
\newenvironment{epigraph}{\collect@body\@storeepigraph}{}
\AtEndDocument{\subsection*{Authors and aﬃliations}
 \footnotesize\parindent0pt%
 \newbool{@odstep}\boolfalse{@odstep}%
 \renewcommand*{\do}[1]{%
  \begin{minipage}[t]{.5\textwidth}%
   \raggedright#1%
  \end{minipage}%
  \ifbool{@odstep}{\boolfalse{@odstep}\par\bigskip}{\booltrue{@odstep}}%
 }
 \dolistloop{\@eiauthors}%
}
%
%
%
\renewcommand{\maketitle}{%
 \ifx\@edoi\undefined\gdef\@epages{***}\gdef\@enumber{xxx}\else\substring[q]{\@edoi}{15}{$}\gdef\@epages{\thestring}\substring[q]{\jobname}{21}{$}\edef\@enumber{\thestring}\fi
 \ifx\afIname\undefined\ClassError{einformatica}{Authors' first name undefined}{}%
 \else%
  \ifx\alIname\undefined\ClassError{einformatica}{Authors' last name undefined}{}%
  \else%
   \def\@eauthorshead{\afIname\space\alIname}%
   \listeadd{\imiona}{\afIname\space\alIname}
  \fi%
 \fi%
 \ifx\alIIname\undefined\else\g@addto@macro\@eauthorshead{,\space\afIIname\space\alIIname}\fi
 \ifx\alIIIname\undefined\else\g@addto@macro\@eauthorshead{,\space\afIIIname\space\alIIIname}%
  \ifx\@eshortauthorshead\undefined%
   \def\@eshortauthorshead{\afIname\space\alIname\space et\space al.}\else\fi%
 \fi
 \ifx\alIVname\undefined\else\g@addto@macro\@eauthorshead{,\space\afIVname\space\alIVname}\fi
 \ifx\alVname\undefined\else\g@addto@macro\@eauthorshead{,\space\afVname\space\alVname}\fi
 \ifx\alVIname\undefined\else\g@addto@macro\@eauthorshead{,\space\afVIname\space\alVIname}\fi
 \ifx\alVIIname\undefined\else\g@addto@macro\@eauthorshead{,\space\afVIIname\space\alVIname}\fi
 \ifx\alVIIIname\undefined\else\g@addto@macro\@eauthorshead{,\space\afVIIIname\space\alVIIname}\fi
 \ifx\alIXname\undefined\else\g@addto@macro\@eauthorshead{,\space\afIXname\space\alIXname}\fi
 \ifx\alXname\undefined\else\g@addto@macro\@eauthorshead{,\space\afXname\space\alXname}\fi
 \ifx\afIname\undefined\ClassError{einformatica}{Authors' first name undefined}{}%
 \else%
  \ifx\alIname\undefined\ClassError{einformatica}{Authors' last name undefined}{}%
  \else%
   \def\@eauthorsbib{\afIname\space\alIname}%
  \fi%
 \fi%
 \ifx\alIIname\undefined\else\g@addto@macro\@eauthorsbib{\space and\space\afIIname\space\alIIname}\fi
 \ifx\alIIIname\undefined\else\g@addto@macro\@eauthorsbib{\space and\space\afIIIname\space\alIIIname}\fi
 \ifx\alIVname\undefined\else\g@addto@macro\@eauthorsbib{\space and\space\afIVname\space\alIVname}\fi
 \ifx\alVname\undefined\else\g@addto@macro\@eauthorsbib{\space and\space\afVname\space\alVname}\fi
 \ifx\alVIname\undefined\else\g@addto@macro\@eauthorsbib{\space and\space\afVIname\space\alVIname}\fi
 \ifx\alVIIname\undefined\else\g@addto@macro\@eauthorsbib{\space\aIafill and\space\afVIIname\space\alVIname}\fi
 \ifx\alVIIIname\undefined\else\g@addto@macro\@eauthorsbib{\space and\spaceg\afVIIIname\space\alVIIname}\fi
 \ifx\alIXname\undefined\else\g@addto@macro\@eauthorsbib{\space and\space\afIXname\space\alIXname}\fi
 \ifx\alXname\undefined\else\g@addto@macro\@eauthorsbib{\space and\space\afXname\space\alXname}\fi
 %
 \def\@pierwszy{%
  \afIname\ifthenelse{\equal{\alIname}{}}{}{\space\alIname}\par %
  \ifthenelse{\equal{\aIemail}{}}{}{e-mail: \href{mailto:\aIemail}{\aIemail}\par}%
  \ifthenelse{\equal{\aIorcid}{}}{}{ORCID: \href{https://orcid.org/\aIorcid}{https://orcid.org/\aIorcid}\par}%
  \ifthenelse{\equal{\aIaffil}{}}{}{\aIaffil}%
 }
 \ifx\afIIname\undefined\else%
  \def\@drugi{%
   \afIIname\ifthenelse{\equal{\alIIname}{}}{}{\space\alIIname}\par %
   \ifthenelse{\equal{\aIIemail}{}}{}{e-mail: \href{mailto:\aIIemail}{\aIIemail}\par}%
   \ifthenelse{\equal{\aIIorcid}{}}{}{ORCID: \href{https://orcid.org/\aIIorcid}{https://orcid.org/\aIIorcid}\par}%
   \ifthenelse{\equal{\aIIaffil}{}}{}{\aIIaffil}%
  }
 \fi
 \ifx\afIIIname\undefined\else%
  \def\@trzeci{%
   \afIIIname\ifthenelse{\equal{\alIIIname}{}}{}{\space\alIIIname}\par %
   \ifthenelse{\equal{\aIIIemail}{}}{}{e-mail: \href{mailto:\aIIIemail}{\aIIIemail}\par}%
   \ifthenelse{\equal{\aIIIorcid}{}}{}{ORCID: \href{https://orcid.org/\aIIIorcid}{https://orcid.org/\aIIIorcid}\par}%
   \ifthenelse{\equal{\aIIIaffil}{}}{}{\aIIIaffil}%
  }
 \fi
 \ifx\afIVname\undefined\else%
  \def\@czwarty{%
   \afIVname\ifthenelse{\equal{\alIVname}{}}{}{\space\alIVname}\par %
   \ifthenelse{\equal{\aIVemail}{}}{}{e-mail: \href{mailto:\aIVemail}{\aIVemail}\par}%
   \ifthenelse{\equal{\aIVorcid}{}}{}{ORCID: \href{https://orcid.org/\aIVorcid}{https://orcid.org/\aIVorcid}\par}%
   \ifthenelse{\equal{\aIVaffil}{}}{}{\aIVaffil}%
  }
 \fi
 \ifx\afVname\undefined\else%
  \def\@piaty{%
   \afVname\ifthenelse{\equal{\alVname}{}}{}{\space\alVname}\par %
   \ifthenelse{\equal{\aVemail}{}}{}{e-mail: \href{mailto:\aVemail}{\aVemail}\par}%
   \ifthenelse{\equal{\aVorcid}{}}{}{ORCID: \href{https://orcid.org/\aVorcid}{https://orcid.org/\aVorcid}\par}%
   \ifthenelse{\equal{\aVaffil}{}}{}{\aVaffil}%
  }
 \fi
 \ifx\afVIname\undefined\else%
  \def\@szosty{%
   \afVIname\ifthenelse{\equal{\alVIname}{}}{}{\space\alVIname}\par %
   \ifthenelse{\equal{\aVIemail}{}}{}{e-mail: \href{mailto:\aVIemail}{\aVIemail}\par}%
   \ifthenelse{\equal{\aVIorcid}{}}{}{ORCID: \href{https://orcid.org/\aVIorcid}{https://orcid.org/\aVIorcid}\par}%
   \ifthenelse{\equal{\aVIaffil}{}}{}{\aVIaffil}%
  }
 \fi
 \ifx\afVIIname\undefined\else%
  \def\@siodmy{%
   \afVIIname\ifthenelse{\equal{\alVIIname}{}}{}{\space\alVIIname}\par %
   \ifthenelse{\equal{\aVIIemail}{}}{}{e-mail: \href{mailto:\aVIIemail}{\aVIIemail}\par}%
   \ifthenelse{\equal{\aVIIorcid}{}}{}{ORCID: \href{https://orcid.org/\aVIIorcid}{https://orcid.org/\aVIIorcid}\par}%
   \ifthenelse{\equal{\aVIIaffil}{}}{}{\aVIIaffil}%
  }
 \fi
 \ifx\afVIIIname\undefined\else%
  \def\@osmy{%
   \afVIIIname\ifthenelse{\equal{\alVIIIname}{}}{}{\space\alVIIIname}\par %
   \ifthenelse{\equal{\aVIIIemail}{}}{}{e-mail: \href{mailto:\aVIIIemail}{\aVIIIemail}\par}%
   \ifthenelse{\equal{\aVIIIorcid}{}}{}{ORCID: \href{https://orcid.org/\aVIIIorcid}{https://orcid.org/\aVIIIorcid}\par}%
   \ifthenelse{\equal{\aVIIIaffil}{}}{}{\aVIIIaffil}%
  }
 \fi
 \ifx\afIXname\undefined\else%
  \def\@dziewiaty{%
   \afIXname\ifthenelse{\equal{\alIXname}{}}{}{\space\alIXname}\par %
   \ifthenelse{\equal{\aIXemail}{}}{}{e-mail: \href{mailto:\aIXemail}{\aIXemail}\par}%
   \ifthenelse{\equal{\aIXorcid}{}}{}{ORCID: \href{https://orcid.org/\aIXorcid}{https://orcid.org/\aIXorcid}\par}%
   \ifthenelse{\equal{\aIXaffil}{}}{}{\aIXaffil}%
  }
 \fi
 \ifx\afXname\undefined\else%
  \def\@dziesiaty{%
   \afXname\ifthenelse{\equal{\alXname}{}}{}{\space\alXname}\par %
   \ifthenelse{\equal{\aXemail}{}}{}{e-mail: \href{mailto:\aXemail}{\aXemail}\par}%
   \ifthenelse{\equal{\aXorcid}{}}{}{ORCID: \href{https://orcid.org/\aXorcid}{https://orcid.org/\aXorcid}\par}%
   \ifthenelse{\equal{\aXaffil}{}}{}{\aXaffil}%
  }
 \fi

 %
 \ifx\@pierwszy\undefined\else\listadd{\@eiauthors}{\@pierwszy}\fi
 \ifx\@drugi\undefined\else \listadd{\@eiauthors}{\@drugi}\fi
 \ifx\@trzeci\undefined\else\listadd{\@eiauthors}{\@trzeci}\fi
 \ifx\@czwarty\undefined\else\listadd{\@eiauthors}{\@czwarty}\fi
 \ifx\@piaty\undefined\else\listadd{\@eiauthors}{\@piaty}\fi
 \ifx\@szosty\undefined\else\listadd{\@eiauthors}{\@szosty}\fi
 \ifx\@siodmy\undefined\else\listadd{\@eiauthors}{\@siodmy}\fi
 \ifx\@osmy\undefined\else\listadd{\@eiauthors}{\@osmy}\fi
 \ifx\@dziewiaty\undefined\else\listadd{\@eiauthors}{\@dziewiaty}\fi
 \ifx\@dziesiaty\undefined\else\listadd{\@eiauthors}{\@dziesiaty}\fi
 %
 \begin{center}
  \ifx\@etitle\undefined%
   \ClassError{einformatica}{Title not defined!}{}
  \else%
   \pdfbookmark[0]{\@etitle}{title}
   {\vspace*{13mm}\bf\titlesize \@etitle\ifx\@ethanks\undefined\else\footnotemark[3]\fi\par}
  \fi%
  \ifx\@esubtitle\undefined\else
   \vspace{2mm} {\large \@esubtitle\par}
  \fi%
  %
  \vspace{7mm}
  {\large%
   \ifx\alIname\undefined\ClassError{einformatyka}{Author not defined!}{}\else%
    \ifthenelse{\equal{\afIname}{}}%
    {}%
    {\afIname%
     \ifthenelse{\equal{\alIname}{}}{}{~\alIname}%
     \ifthenelse{\equal{\aIcorr}{}}{}{\textsuperscript{*}}%
     \ifthenelse{\equal{\aIorcid}{}}{}{\orcid{\aIorcid}}%
     \ifx\alIIname\undefined%
     \else,\ %
     \fi%
    }%
   \fi%
   \ifx\alIIname\undefined\else%
    \ifthenelse{\equal{\afIIname}{}}%
    {}%
    {\afIIname%
     \ifthenelse{\equal{\alIIname}{}}{}{~\alIIname}%
     \ifthenelse{\equal{\aIIcorr}{}}{}{\textsuperscript{*}}%
     \ifthenelse{\equal{\aIIorcid}{}}{}{\orcid{\aIIorcid}}%
     \ifx\alIIIname\undefined%
     \else%
      ,\ %
     \fi%
    }%
   \fi%
   \ifx\alIIIname\undefined\else%
    \ifthenelse{\equal{\afIIIname}{}}%
    {}%
    {\afIIIname%
     \ifthenelse{\equal{\alIIIname}{}}{}{~\alIIIname}%
     \ifthenelse{\equal{\aIIIcorr}{}}{}{\textsuperscript{*}}%
     \ifthenelse{\equal{\aIIIorcid}{}}{}{\orcid{\aIIIorcid}}%
     \ifx\alIVname\undefined%
     \else%
      ,\ %
     \fi%
    }%
   \fi%
   \ifx\alIVname\undefined\else
    \ifthenelse{\equal{\afIVname}{}}%
    {}%
    {\afIVname%
     \ifthenelse{\equal{\alIVname}{}}{}{~\alIVname}%
     \ifthenelse{\equal{\aIVcorr}{}}{}{\textsuperscript{*}}%
     \ifthenelse{\equal{\aIVorcid}{}}{}{\orcid{\aIVorcid}}%
     \ifx\alVname\undefined%
     \else%
      ,\ %
     \fi%
    }%
   \fi%
   \ifx\alVname\undefined\else
    \ifthenelse{\equal{\afVname}{}}%
    {}%
    {\afVname
     \ifthenelse{\equal{\alVname}{}}{}{~\alVname}%
     \ifthenelse{\equal{\aVcorr}{}}{}{\textsuperscript{*}}%
     \ifthenelse{\equal{\aVorcid}{}}{}{\orcid{\aVorcid}}%
     \ifx\alVIname\undefined%
     \else%
      ,\ %
     \fi%
    }%
   \fi%
   \ifx\alVIname\undefined\else
    \ifthenelse{\equal{\afVIname}{}}%
    {}%
    {\afVIname
     \ifthenelse{\equal{\alVIname}{}}{}{~\alVIname}%
     \ifthenelse{\equal{\aVIcorr}{}}{}{\textsuperscript{*}}%
     \ifthenelse{\equal{\aVIorcid}{}}{}{\orcid{\aVIorcid}}%
     \ifx\alVIIname\undefined%
     \else%
      ,\ %
     \fi%
    }%
   \fi%
   \ifx\alVIIname\undefined\else
    \ifthenelse{\equal{\afVIIname}{}}%
    {}%
    {\afVIIname
     \ifthenelse{\equal{\alVIIname}{}}{}{~\alVIIname}%
     \ifthenelse{\equal{\aVIIcorr}{}}{}{\textsuperscript{*}}%
     \ifthenelse{\equal{\aVIIorcid}{}}{}{\orcid{\aVIIorcid}}%
     \ifx\alVIIIname\undefined%
     \else%
      ,\ %
     \fi%
    }%
   \fi%
   \ifx\alVIIIname\undefined\else
    \ifthenelse{\equal{\afVIIIname}{}}%
    {}%
    {\afVIIIname
     \ifthenelse{\equal{\alVIIIname}{}}{}{~\alVIIIname}%
     \ifthenelse{\equal{\aVIIIcorr}{}}{}{\textsuperscript{*}}%
     \ifthenelse{\equal{\aVIIIorcid}{}}{}{\orcid{\aVIIIorcid}}%
     \ifx\alIXname\undefined%
     \else%
      ,\ %
     \fi%
    }%
   \fi%
   \ifx\alIXname\undefined\else
    \ifthenelse{\equal{\afIXname}{}}%
    {}%
    {\afIXname
     \ifthenelse{\equal{\alIXname}{}}{}{~\alIXname}%
     \ifthenelse{\equal{\aIXcorr}{}}{}{\textsuperscript{*}}%
     \ifthenelse{\equal{\aIXorcid}{}}{}{\orcid{\aIXorcid}}%
     \ifx\alXname\undefined%
     \else%
      ,\ %
     \fi%
    }%
   \fi%
   \ifx\alXname\undefined\else
    \ifthenelse{\equal{\afXname}{}}%
    {}%
    {\afXname
     \ifthenelse{\equal{\alXname}{}}{}{~\alXname}%
     \ifthenelse{\equal{\aXcorr}{}}{}{\textsuperscript{*}}%
     \ifthenelse{\equal{\aXorcid}{}}{}{\orcid{\aXorcid}}%
    }%
   \fi%

  }\par
  {\footnotesize  %
   \ifthenelse{\isundefined{\aIcorr}}{}{\ifthenelse{\equal{\aIcorr}{}}{}{\stepcounter{@einumcorr}}}%
   \ifthenelse{\isundefined{\aIIcorr}}{}{\ifthenelse{\equal{\aIIcorr}{}}{}{\stepcounter{@einumcorr}}}%
   \ifthenelse{\isundefined{\aIIIcorr}}{}{\ifthenelse{\equal{\aIIIcorr}{}}{}{\stepcounter{@einumcorr}}}%
   \ifthenelse{\isundefined{\aIVcorr}}{}{\ifthenelse{\equal{\aIVcorr}{}}{}{\stepcounter{@einumcorr}}}%
   \ifthenelse{\isundefined{\aVcorr}}{}{\ifthenelse{\equal{\aVcorr}{}}{}{\stepcounter{@einumcorr}}}%
   \ifthenelse{\isundefined{\aVIcorr}}{}{\ifthenelse{\equal{\aVIcorr}{}}{}{\stepcounter{@einumcorr}}}%
   \ifthenelse{\isundefined{\aVIIcorr}}{}{\ifthenelse{\equal{\aVIIcorr}{}}{}{\stepcounter{@einumcorr}}}%
   \ifthenelse{\isundefined{\aVIIIcorr}}{}{\ifthenelse{\equal{\aVIIIcorr}{}}{}{\stepcounter{@einumcorr}}}%
   \ifthenelse{\isundefined{\aIXcorr}}{}{\ifthenelse{\equal{\aIXcorr}{}}{}{\stepcounter{@einumcorr}}}%
   \ifthenelse{\isundefined{\aXcorr}}{}{\ifthenelse{\equal{\aXcorr}{}}{}{\stepcounter{@einumcorr}}}%
   %
   \ifthenelse{\the@einumcorr > 0}{\textsuperscript{*}Corresponding author\ifthenelse{\the@einumcorr > 1}{s}{}:\space{}}{\ClassError{einformatica}{Corresponding Author not defined!}{}}%
   %
   \ifthenelse{\isundefined{\aIcorr}}{}{\ifthenelse{\equal{\aIcorr}{}}{}{\mailto{\aIemail}\def\@@f{}}}%
   \ifthenelse{\isundefined{\aIIcorr}}{}{\ifthenelse{\equal{\aIIcorr}{}}{}{\ifthenelse{\isundefined{\@@f}}{}{,\space}\mailto{\aIIemail}\def\@@f{}}}%
   \ifthenelse{\isundefined{\aIIIcorr}}{}{\ifthenelse{\equal{\aIIIcorr}{}}{}{\ifthenelse{\isundefined{\@@f}}{}{,\space}\mailto{\aIIIemail}\def\@@f{}}}%
   \ifthenelse{\isundefined{\aIVcorr}}{}{\ifthenelse{\equal{\aIVcorr}{}}{}{\ifthenelse{\isundefined{\@@f}}{}{,\space}\mailto{\aIVemail}\def\@@f{}}}%
   \ifthenelse{\isundefined{\aVcorr}}{}{\ifthenelse{\equal{\aVcorr}{}}{}{\ifthenelse{\isundefined{\@@f}}{}{,\space}\mailto{\aVemail}\def\@@f{}}}%
   \ifthenelse{\isundefined{\aVIcorr}}{}{\ifthenelse{\equal{\aVIcorr}{}}{}{\ifthenelse{\isundefined{\@@f}}{}{,\space}\mailto{\aVIemail}\def\@@f{}}}%
   \ifthenelse{\isundefined{\aVIIcorr}}{}{\ifthenelse{\equal{\aVIIcorr}{}}{}{\ifthenelse{\isundefined{\@@f}}{}{,\space}\mailto{\aVIIemail}\def\@@f{}}}%
   \ifthenelse{\isundefined{\aVIIIcorr}}{}{\ifthenelse{\equal{\aVIIIcorr}{}}{}{\ifthenelse{\isundefined{\@@f}}{}{,\space}\mailto{\aVIIIemail}\def\@@f{}}}%
   \ifthenelse{\isundefined{\aIXcorr}}{}{\ifthenelse{\equal{\aIXcorr}{}}{}{\ifthenelse{\isundefined{\@@f}}{}{,\space}\mailto{\aIXemail}\def\@@f{}}}%
   \ifthenelse{\isundefined{\aXcorr}}{}{\ifthenelse{\equal{\aXcorr}{}}{}{\ifthenelse{\isundefined{\@@f}}{}{,\space}\mailto{\aXemail}\def\@@f{}}}%
   \par
  } %
 \end{center}
 %
 %
 \vspace{1mm}
 \ifx\@eepigraph\undefined\else
  \vspace{5mm}
  \begin{minipage}{0.9\textwidth}
   \begin{flushright}
    %
    \small \@eepigraph
   \end{flushright}
  \end{minipage}
 \fi
 %
 \ifx\@eabstract\undefined%
  \ClassError{einformatica}{Abstract not defined!}{}%
 \else%
  \vspace{5mm}  %
  %
  \begin{minipage}[t]{4.5cm}\small
   \textbf{Article info}\par
   \rule{\textwidth}{1pt}\par\footnotesize\raggedright%
   \ifx\@DataLink\undefined\else Dataset link: \url{\@DataLink}\par\rule{\textwidth}{0.4pt}\par\fi%
   \renewcommand*{\do}[1]{##1\\}%
   \textbf{Keywords:}\\\expandafter\docsvlist\expandafter{\@ekeywordset}
   \par
   \rule{\textwidth}{0.4pt}\par
   Submitted: \@eIsubmitted\\
   Revised: \@eIrevised\\
   Accepted: \@eIaccepted\\
   Available online: \@eIpublished
  \end{minipage}\hspace{1cm}%
  \begin{minipage}[t]{9.5cm}\footnotesize
   {\bf Abstract}\par
   \rule{\textwidth}{1pt}\par\footnotesize%

   \@eabstract%
  \end{minipage} \vspace{0mm}%
 \fi\par
 %
 \ifx\@ekeywordset\undefined\else%
  \vspace{0mm}%
  %
 \fi\par
 \hypersetup{%
  pdftitle = {\@etitle},
  pdfauthor = {\@eauthorshead},
  pdfkeywords = {\ifx\@ekeywordset\undefined\else\@ekeywordset\fi},
  pdfsubject = {e-Informatica Software Engineering Journal, Volume \@volume, Issue \@issue, \@eIyear}
 }
 \newcounter{aaa}\newcounter{aab}
 \setcounterpageref{aaa}{FirstPage}
 \setcounterpageref{aab}{LastPage}
 \IfFileExists{redakcja}{
  \addtostream{meta}{\noexpand\def\noexpand\eIsubmitted{\@eIsubmitted}}
  \addtostream{meta}{\noexpand\def\noexpand\eIrevised{\@eIrevised}}
  \addtostream{meta}{\noexpand\def\noexpand\eIaccepted{\@eIaccepted}}
  \addtostream{meta}{\noexpand\def\noexpand\eIpublished{\@eIpublished}}
  %
  %
  %
  \addtostream{bibs}{@article\@charlb\jobname,}
  \addtostream{bibs}{  author = {\@eauthorsbib},}
  \addtostream{bibs}{  title = {\@etitle},}
  \if@eb\else\addtostream{bibs}{  pages = {\arabic{aaa}--\arabic{aab}},}\fi
  \ifx\@edoi\undefined\else\addtostream{bibs}{  doi = {\@edoi},}\fi
  \addtostream{bibs}{  year = {\@eIyear},}
  \addtostream{bibs}{  volume = {\@volume},}
  \addtostream{bibs}{  number = {\@issue},}
  \addtostream{bibs}{  keywords = {\@ekeywordset},}
  \addtostream{bibs}{  journal = {e-Informatica Software Engineering Journal},}
  \addtostream{bibs}{  url = {\@strona},}
  \addtostream{bibs}{  abstract = {\@eabstract},}
  \addtostream{bibs}{  note = {Available online: \@eIpublished},}
  \addtostream{bibs}{\@charrb}
  %
  \addtostream{doi}{|                                        |                                                              |}
  \addtostream{doi}{| -------------------------------------: | ------------------------------------------------------------ |}
  \addtostream{doi}{|                  **TYTUŁ WYDAWNICTWA** | e-Informatica Software Engineering Journal                   |}
  \addtostream{doi}{|              **WOLUMIN / NUMER / ROK** | \@volume/\@issue/\@eIyear                                                    |}
  \addtostream{doi}{|                    **AUTOR / AUTORZY** | \@eauthorshead |}
  \addtostream{doi}{|                              **TYTUŁ** | \@etitle |}
  \addtostream{doi}{|          **STRESZCZENIE (opcjonalne)** | \@eabstract |}
  \addtostream{doi}{|                **JĘZYK  (opcjonalne)** | en                                                           |}
  \addtostream{doi}{|        **ROK PUBLIKACJI (opcjonalne)** | \@eIyear |}
  \ifx\@edoi\undefined\else\substring[q]{\@edoi}{15}{$}
   \addtostream{doi}{|                **STRONY (opcjonalne)** | \thestring |}
   \addtostream{doi}{|                                **DOI** | \@edoi |}
  \fi
  \addtostream{doi}{|    **URL OBIEKTU  (strony lub pliku)** | \@strona |}
  \addtostream{doi}{| **URL DOKUMENTU  (pliku; opcjonalne)** | |}
 }{}
 %

}
\AtBeginDocument{\label{FirstPage}}
%
\widowpenalty=10000
\clubpenalty=10000
%
\flushbottom
