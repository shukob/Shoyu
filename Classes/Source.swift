//
//  Source.swift
//  Shoyu
//
//  Created by asai.yuki on 2015/12/12.
//  Copyright © 2015年 yukiasai. All rights reserved.
//

import UIKit

open class Source: NSObject {
    open fileprivate(set) var sections = [SectionType]()

    public var scrollViewDelegate: UIScrollViewDelegate?

    public override init() {
        super.init()
    }

    public convenience init(closure: ((Source) -> Void)) {
        self.init()
        closure(self)
    }

    open var didMoveRow: ((IndexPath, IndexPath) -> Void)?

    func isPermitIndexPath(_ indexPath: IndexPath) -> Bool {
        return sections.count > (indexPath as NSIndexPath).section && sections[(indexPath as NSIndexPath).section].rows.count > (indexPath as NSIndexPath).row
    }

    @discardableResult open func add(section: SectionType) -> Self {
        sections.append(section)
        return self
    }

    @discardableResult open func add(sections: [SectionType]) -> Self {
        self.sections.append(contentsOf: sections)
        return self
    }

    @discardableResult open func createSection<H, F>(closure: ((Section<H, F>) -> Void)) -> Self {
        return add(section: Section<H, F>() { closure($0) })
    }

    @discardableResult open func createSections<H, F, E>(for elements: [E], closure: ((E, Section<H, F>) -> Void)) -> Self {
        return add(sections:
            elements.map { element -> Section<H, F> in
                return Section<H, F>() { closure(element, $0) }
                }.map { $0 as SectionType }
        )
    }

    @discardableResult open func createSections<H, F>(for count: UInt, closure: ((UInt, Section<H, F>) -> Void)) -> Self {
        return createSections(for: [UInt](0..<count), closure: closure)
    }

}

public extension Source {
    public func section(for section: Int) -> SectionType {
        return sections[section]
    }

    public func section(for indexPath: IndexPath) -> SectionType {
        return self.section(for: (indexPath as NSIndexPath).section)
    }

    public func moveRow(_ sourceIndexPath: IndexPath, destinationIndexPath: IndexPath) {
        let row = self.section(for: sourceIndexPath).removeRow((sourceIndexPath as NSIndexPath).row)
        self.section(for: destinationIndexPath).insertRow(row, index: (destinationIndexPath as NSIndexPath).row)
    }
}

// MARK: - Table view data source

extension Source: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.section(for: section).rowCount
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = self.section(for: indexPath).rowFor(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        if let delegate = row as? RowDelegateType {
            delegate.configureCell(tableView, cell: cell, indexPath: indexPath)
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = self.section(for: section).header else {
            return nil
        }
        return sectionHeaderFooterViewFor(header, tableView: tableView, section: section)
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = self.section(for: section).footer else {
            return nil
        }
        return sectionHeaderFooterViewFor(footer, tableView: tableView, section: section)
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let header = self.section(for: section).header else {
            return nil
        }
        return sectionHeaderFooterTitleFor(header, tableView: tableView, section: section)
    }

    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let footer = self.section(for: section).footer else {
            return nil
        }
        return sectionHeaderFooterTitleFor(footer, tableView: tableView, section: section)
    }

    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let delegate = self.section(for: indexPath).rowFor(indexPath) as? RowDelegateType {
            return delegate.canEdit(tableView, indexPath: indexPath)
        }
        return false
    }

    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if let delegate = self.section(for: indexPath).rowFor(indexPath) as? RowDelegateType {
            return delegate.canMove(tableView, indexPath: indexPath)
        }
        return false
    }

    @objc(tableView:editingStyleForRowAtIndexPath:)
    public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard let delegate = self.section(for: indexPath).rowFor(indexPath) as? RowDelegateType else {
            return .none
        }
        return delegate.canRemove(tableView, indexPath: indexPath) ? .delete : .none
    }

    @objc(tableView:shouldIndentWhileEditingRowAtIndexPath:)
    public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        guard let delegate = self.section(for: indexPath).rowFor(indexPath) as? RowDelegateType else {
            return false
        }
        return delegate.canRemove(tableView, indexPath: indexPath)
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let delegate = self.section(for: indexPath).rowFor(indexPath) as? RowDelegateType else {
            return
        }

        switch editingStyle {
        case .delete:
            self.section(for: indexPath).removeRow((indexPath as NSIndexPath).row)
            let animation = delegate.willRemove(tableView, indexPath: indexPath)
            tableView.deleteRows(at: [indexPath], with: animation)
            delegate.didRemove(tableView, indexPath: indexPath)
        default:
            break
        }
    }
}

// MARK: - Table view delegate

extension Source: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = self.section(for: indexPath).rowFor(indexPath)
        if let delegate = row as? RowDelegateType,
            let height = delegate.heightFor(tableView, indexPath: indexPath) {
            return height
        }
        return tableView.rowHeight
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = self.section(for: indexPath).rowFor(indexPath)
        if let delegate = row as? RowDelegateType,
            let estimatedHeight = delegate.estimatedHeightFor(tableView, indexPath: indexPath) {
            return estimatedHeight
        }
        return tableView.estimatedRowHeight
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let header = self.section(for: section).header else {
            return 0
        }
        return sectionHeaderFooterHeightFor(header, tableView: tableView, section: section) ?? tableView.sectionHeaderHeight
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let footer = self.section(for: section).footer else {
            return 0
        }
        return sectionHeaderFooterHeightFor(footer, tableView: tableView, section: section) ?? tableView.sectionFooterHeight
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = self.section(for: indexPath).rowFor(indexPath) as? RowDelegateType
        row?.didSelect(tableView, indexPath: indexPath)
    }

    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let row = self.section(for: indexPath).rowFor(indexPath) as? RowDelegateType
        row?.didDeselect(tableView, indexPath: indexPath)
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let row = self.section(for: indexPath).rowFor(indexPath) as? RowDelegateType
        row?.willDisplayCell(tableView, cell: cell, indexPath: indexPath)
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !isPermitIndexPath(indexPath) {
            return
        }
        let row = self.section(for: indexPath).rowFor(indexPath) as? RowDelegateType
        row?.didEndDisplayCell(tableView, cell: cell, indexPath: indexPath)
    }

    @objc(tableView:moveRowAtIndexPath:toIndexPath:)
    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        moveRow(sourceIndexPath, destinationIndexPath: destinationIndexPath)
        didMoveRow?(sourceIndexPath, destinationIndexPath)
    }

    public func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard let row = self.section(for: sourceIndexPath).rowFor(sourceIndexPath) as? RowDelegateType else {
            return sourceIndexPath
        }
        return row.canMoveTo(tableView, sourceIndexPath: sourceIndexPath, destinationIndexPath: proposedDestinationIndexPath) ? proposedDestinationIndexPath : sourceIndexPath
    }
}

// MARK: - Scroll View Delegate
extension Source: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidZoom?(scrollView)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollViewDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollViewDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollViewDelegate?.viewForZooming?(in: scrollView)
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollViewDelegate?.scrollViewWillBeginZooming!(scrollView, with: view)
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollViewDelegate?.scrollViewDidEndZooming!(scrollView, with: view, atScale: scale)
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return scrollViewDelegate?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }

    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidScrollToTop?(scrollView)
    }

}

// MARK: Private method

extension Source {
    fileprivate func sectionHeaderFooterViewFor(_ headerFooter: SectionHeaderFooterType, tableView: UITableView, section: Int) -> UIView? {
        // Dequeue
        if let identifier = headerFooter.reuseIdentifier,
            let view = dequeueReusableView(tableView, identifier: identifier) {
            if let delegate = headerFooter as? SectionHeaderFooterDelegateType {
                delegate.configureView(tableView, view: view, section: section)
            }
            if let cell = view as? UITableViewCell {
                return cell.contentView
            }
            return view
        }

        // Create view
        if let delegate = headerFooter as? SectionHeaderFooterDelegateType,
            let view = delegate.viewFor(tableView, section: section) {
            delegate.configureView(tableView, view: view, section: section)
            if let cell = view as? UITableViewCell {
                return cell.contentView
            }
            return view
        }
        return nil
    }

    fileprivate func sectionHeaderFooterTitleFor(_ headerFooter: SectionHeaderFooterType, tableView: UITableView, section: Int) -> String? {
        if let delegate = headerFooter as? SectionHeaderFooterDelegateType,
            let title = delegate.titleFor(tableView, section: section) {
            return title
        }
        return nil
    }

    fileprivate func dequeueReusableView(_ tableView: UITableView, identifier: String) -> UIView? {
        if let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) {
            return view
        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) {
            return cell
        }
        return nil
    }

    fileprivate func sectionHeaderFooterHeightFor(_ headerFooter: SectionHeaderFooterType, tableView: UITableView, section: Int) -> CGFloat? {
        if let delegate = headerFooter as? SectionHeaderFooterDelegateType,
            let height = delegate.heightFor(tableView, section: section) {
            return height
        }
        return nil
    }
}

