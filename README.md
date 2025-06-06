# Portfolio - "Machi Vigil"
■サービス概要

「自分達の街を自分達で見守ろう！」というコンセプトに基づき、Googleマップを利用して街の安全情報を
共有できるアプリ。事故や災害・迷惑行為・行方不明者などに関する情報を住民同士で共有し、助け合える
コミュニティの構築を目的としている。

■ このサービスへの思い・作りたい理由

「悲しいニュースを見たくないし聞きたくない。真っ当に頑張って生きている人たちがひどい目に遭ったり、辛い目に遭う世の中は間違っている。」
「生活圏外のことまで気に掛けることは難しいが、目の届く範囲、手の届く範囲のことなら何かできるのでは？」
そんな想いから、街で起こっている問題を共有できるアプリを作りたいと考えた。
ヒーローのように助けを求める人の前に現れ、悪を挫くことはできなくとも、ほんの少し周りのことを気に掛けるだけで、世の中を少しでも良くできるはず。
「女性や子供が誰かに付けられているかもしれないと感じたとき」「大雨で冠水している道路があるとき」
「深夜に集まっている怖い集団がいるとき」「熊や猪が街に出没したとき」など、街の安全や住民の安心のための情報であれば
何でも共有してもらえるサービスにしたい。

■ ユーザー層について

対象：全世代
- 困っている人や街の安全に不安を感じた人が情報を発信し、周囲の人が力になれるようにするため、利用者は全年齢対象とする。
- 「この辺が危ない」「この先で事故が起きている」といった安全情報を提供するのに年齢制限は不要。
- 親子連れや女性、高齢者、夜間移動の多い人など、特に安全情報を必要とする人にとって有益。

■サービスの利用イメージ

1. 情報投稿
   - 街の安全や街に住む人の不安・困り事などの情報を、Googleマップ上でピンポイント指定またはエリア指定で投稿。
   - 緊急度を設定し、テキスト・画像を添付して詳細を記入。

2. 情報閲覧
   - ユーザーの現在地や住居周辺などの情報をGoogleマップ上で確認。
   - 緊急度別にマーカーの色が異なり、視覚的にわかりやすい。

3. チャット機能
   - 情報詳細ページでリアルタイムのやり取りが可能。
   - 「変な人がついてくる。」「この道は通れますか？」などの投稿や質問ができる。

4. コミュニティ機能
   - ユーザー同士がグループを作成し、情報を共有。
   - 近隣住民で助け合う仕組みを作ることで、治安の向上を促進。

■ ユーザーの獲得について

- 家族・友人などに使ってもらい、利便性を広める。
- 地方自治体や警察の公式X（旧Twitter）アカウントなどからアプローチする。
- 町内会や防犯団体などにもアプローチする。

■ サービスの差別化ポイント・推しポイント
- 行政や警察からの発信情報ではなく、街の住民自身が情報発信できる点
   - 既存の防犯・災害情報アプリは自治体からの一方的な発信が多いが、本アプリは住民同士の情報共有を促す。
   - 住民同士で情報を発信・共有することで、事件や事故・災害を予防できる可能性が広がる。
- リアルタイムのやり取りが可能
   - 情報投稿後、チャット機能で状況を共有・更新できる。
- 緊急度別の色分け表示
   - Googleマップ上に表示することで、一目で「どの情報が緊急度が高い情報なのか」がわかる。
- コミュニティ機能による地域密着型の情報共有
   - 自警団的な役割を持つグループを作成可能。
   - 地域ごとに最適な情報を集約できる。

■ 機能候補
  - MVPリリース
     - アカウント作成機能
     - ログイン機能
     - 情報作成機能
        - 現在地または住居地などの緯度・経度を利用
        - カテゴリー選択（事故、災害、不審者情報など）
        - 緊急度の設定
        - 対象地をピンポイント指定、またはエリア指定で選択
        - 画像添付・詳細入力
     - 情報閲覧機能
        - Googleマップ上にマーカーで情報を表示（緊急度ごとに色分け）
        - マーカーから情報詳細画面へ遷移可能
        - 情報一覧表示
     - チャット機能
        - 情報詳細画面でリアルタイムのやり取り可能
  - 本リリース
     - 情報登録方法のチュートリアル機能
     - コミュニティ作成機能
        - ユーザーがグループを作成し、情報を共有できる（コミュニティ内チャット有り）
        - コミュニティ管理機能（編集・削除・権限譲渡など）
     - コミュニティ一覧表示機能
        - 住所周辺のコミュニティを検索可能
     - コミュニティ参加機能
        - 参加申請制（管理者の承認が必要）
     - フォロー機能
        - フォローしたユーザーの投稿情報が表示されるようになる
   - 本リリース後のissue
     - アプリ管理機能(admin用)
     - 情報詳細ページの閲覧数表示機能
     - 情報詳細ページに対する「いいね」機能
     - 不良情報通報機能
     - 不良アカウント通報機能

■ 機能の実装方針予定
  - ログイン機能
    - gem devise
  - 地図表示、緯度・経度取得機能
    - Google Maps Platform
      - Maps JavaScript API
      - Geocoding API
    - gem geocoder
  - チャット機能
    - Action Cable
  - 画像保存機能
    - gem carrierwave

■ 画面遷移図
- Figma
  - モバイル：https://www.figma.com/design/QtKfnrawFad3U3L5oNvE6V/%E5%8D%92%E6%A5%AD%E5%88%B6%E4%BD%9C%EF%BC%88%E3%83%A2%E3%83%90%E3%82%A4%E3%83%AB%E7%89%88%EF%BC%89?node-id=0-1&t=sDZ2WVwxkQOtnIZO-1
  - PC：https://www.figma.com/design/3lslGnmtzCGlYvTB3TyLqb/%E5%8D%92%E6%A5%AD%E5%88%B6%E4%BD%9C%EF%BC%88PC%E7%89%88%EF%BC%89?node-id=0-1&t=Vp2lcKZVA32kM1WD-1

  ■ ER図
- draw.io
  - https://drive.google.com/file/d/1_7sZqlWi08qtjaD0CZrJScHfY-ItQv2s/view?usp=sharing
