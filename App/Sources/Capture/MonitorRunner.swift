// App/Sources/Capture/MonitorRunner.swift
import AppKit
import ClipKeepCore

/// Drives ClipboardMonitor.poll() on a background timer with an adaptive interval,
/// pausing while the machine sleeps or the screen is locked.
///
/// `@unchecked Sendable`: every access to the mutable state below (`timer`,
/// `lastChangeAt`, `isPaused`) and to the non-Sendable `monitor` happens on the
/// private serial `queue`, so the type is internally race-free. The compiler can't
/// prove this, hence the unchecked conformance.
final class MonitorRunner: @unchecked Sendable {
    private let monitor: ClipboardMonitor
    private let queue = DispatchQueue(label: "com.clipkeep.monitor", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var lastChangeAt = Date.distantPast
    private var _isPaused = false

    private let fastInterval: TimeInterval = 0.3
    private let slowInterval: TimeInterval = 1.0
    private let activeWindow: TimeInterval = 10

    init(monitor: ClipboardMonitor) {
        self.monitor = monitor
        observeSleepWake()
    }

    func start() {
        queue.async { [weak self] in self?.scheduleNext() }
    }

    func setPaused(_ paused: Bool) {
        queue.async { [weak self] in
            guard let self else { return }
            self._isPaused = paused
            if paused { self.timer?.cancel(); self.timer = nil }
            else { self.scheduleNext() }
        }
    }

    // MARK: - Queue-confined internals

    private func scheduleNext() {
        guard !_isPaused else { return }
        let interval = Date().timeIntervalSince(lastChangeAt) < activeWindow ? fastInterval : slowInterval
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + interval)
        t.setEventHandler { [weak self] in self?.tick() }
        timer = t
        t.resume()
    }

    private func tick() {
        let before = monitor.lastChangeCount
        monitor.poll()
        if monitor.lastChangeCount != before { lastChangeAt = Date() }
        scheduleNext()
    }

    private func observeSleepWake() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: nil) { [weak self] _ in
            self?.setPaused(true)
        }
        nc.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.setPaused(false)
        }
    }
}
