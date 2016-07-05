class BlackBar: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = [.FlexibleWidth, .FlexibleBottomMargin]
        backgroundColor = .blackColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 20)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.frame.size.height = 20
    }

}
